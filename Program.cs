using System.Collections.Concurrent;

Console.WriteLine("Starting crash scenario...");
var random = new Random();

/*
 * With DOTNET_EnableWriteXorExecute=1 set (default), the following code will throw an AccessViolationException
 * when AMD64 is emulated on Apple Silicon using Rosetta 2 like in Docker.
 * Alternatively it also could seg fault the entire program.
 */
var stringDict  = new ConcurrentDictionary<string, bool>();
// The task is not required to reproduce, ensures thread crashes instead of entire program, sometimes.
Task.Run(() =>
{
    while (true)
    {
        stringDict.TryAdd(random.Next(0xFFFF).ToString(), true);
    }
}).Wait(TimeSpan.FromSeconds(2));

// Ensure error is flushed
SpinWait.SpinUntil(() => false, TimeSpan.FromSeconds(1));
Console.WriteLine("Exiting");
