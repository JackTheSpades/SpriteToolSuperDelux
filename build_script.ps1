mkdir build
Set-Location build
cmake -G "Visual Studio 16 2019" -A Win32 -S ..
cmake --build . --config Release
Set-Location ..
Set-Location "src/CFG Editor"
dotnet add package Newtonsoft.Json --version 10.0.3
dotnet build "CFG Editor.sln" -c Release
Set-Location ..
Set-Location ..
