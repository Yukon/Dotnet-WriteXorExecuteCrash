.NET 8 AMD64 Crash on Docker using Rosseta 2
=======================================
This is a simple project to reproduce a crash on .NET 8 running in AMD64 container on Docker using Rosseta 2 on Apple Silicon.

The crash is caused by a new runtime feature [Write xor Execute](https://devblogs.microsoft.com/dotnet/announcing-net-6-preview-7/#runtime-wx-write-xor-execute-support-for-all-platforms-and-architectures) that is enabled by default in .NET 7 and subsequently .NET 8.

## Workaround
To workaround this issue, set the environment variable `DOTNET_EnableWriteXorExecute` to `0` before running the application. This can be done using the Dockerfile like used in this example or numerous other ways.

## Repoduction
To reproduce this issue a Mac with Apple Silicon is required and Docker Desktop for Mac with "Use Rosetta for x86_64/amd64 emulation on Apple Silicon" enabled.
1. Clone this repository
2. Run `docker build -t net8-amd64-crash .`
3. Run `docker run net8-amd64-crash` Note: Warning about "requested image's platform (linux/amd64) [...]" is expected.
4. The program will either report a "Fatal error. System.AccessViolationException" or segfault in which case there will be no "Exiting" message and will have an exit code of 139.

## Symotoms
The symptoms of this issue are widespread and exibit themselves in many different ways. Below are some examples that have been resolved by disabling W^E.

### dotnet restore hangs
When running `dotnet restore` the process will hang and never complete.

### Fatail error. System.AccessViolationException
Application will throw "Fatal error. System.AccessViolationException".

### Segfault
Application will segfault and exit with code 139.

### assertion failed [block != nullptr]
Application outputs to console and crashes with exit code 133.
```
assertion failed [block != nullptr]: BasicBlock requested for unrecognized address
(BuilderBase.h:550 block_for_offset)
```

### Root Cause
There are [two allocator features](https://github.com/dotnet/runtime/blob/477de3419157d809dc266ea03ff3fb4c05f3d1c1/src/coreclr/utilcode/executableallocator.cpp#L123-L142) in the coreclr runtime that check `g_isWXorXEnabled` to enable specific functionality based on the `DOTNET_EnableWriteXorExecute` environment variable.

Most intrestingly is `ExecutableAllocator::IsDoubleMappingEnabled` has a check `#if defined(HOST_OSX) && defined(HOST_ARM64)` which forces the double mapping to be disabled otherwise falling back to `g_isWXorXEnabled`. Double mapping is not supported in Apple Silicon using Rosetta, [which was intended to be fixed](https://github.com/dotnet/runtime/pull/70912). This is not completly the case though as the emulation check occures in the underlying `doublemapping.cpp` not in the allocator that has the `IsDoubleMappingEnabled`. This gap results in double mapping being implied it is enabled resulting in inapproprate memory calls in the allocator as well as double mapping methods without the `IsProcessTranslated` guard clause. By disabling W^E the `IsDoubleMappingEnabled` method always returns false, preventing any double mapping from occuring.

The other enabled check `ExecutableAllocator::IsWXORXEnabled` is less intresting in that on Apple Silicon W^E is a requirment and thus is always enabled. Thereby having this specific funcitonality enabled in a virtualized environment would be supported and only enhance security at the cost of some performance.
