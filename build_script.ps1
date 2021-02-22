mkdir build
Set-Location build
cmake -G "Visual Studio 16 2019" -A Win32 -S ..
cmake --build . --config Release
Set-Location ..
Set-Location "src/CFG Editor/CFG Editor"
Get-ChildItem
Pause
nuget install Newtonsoft.Json -Version 10.0.3 -OutputDirectory packages
dotnet restore
dotnet build "CFG Editor Project.csproj" -c Release
Set-Location ..
Set-Location ..
Set-Location ..