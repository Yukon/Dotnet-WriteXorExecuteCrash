FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Debug
# Disable W^E to ensure dotnet restore is succesful when Rosseta Vtrzed.
ENV DOTNET_EnableWriteXorExecute=0

WORKDIR /src
COPY ["WriteXorExecuteCrash.csproj", "WriteXorExecuteCrash.csproj"]
RUN dotnet restore "WriteXorExecuteCrash.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "WriteXorExecuteCrash.csproj" --no-restore -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "WriteXorExecuteCrash.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
# Change this to '0' to disable functionality to fix the issue
ENV DOTNET_EnableWriteXorExecute=1
ENTRYPOINT ["dotnet", "WriteXorExecuteCrash.dll"]
