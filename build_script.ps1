mkdir build
Set-Location build
cmake -G "Visual Studio 16 2019" -A Win32 -S ..
cmake --build . --config Release
Set-Location ..
Set-Location "src/CFG Editor"
nuget install Newtonsoft.Json -Version 10.0.3 -OutputDirectory packages
Set-Location "CFG Editor"
dotnet restore
msbuild "CFG Editor Project.csproj" -p:Configuration=Release
Set-Location ..
Set-Location ..
Set-Location ..