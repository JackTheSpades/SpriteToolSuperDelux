# build CFG Editor first
Push-Location "src/CFG Editor"
nuget install Newtonsoft.Json -Version 13.0.1
Push-Location "CFG Editor"
dotnet restore
msbuild.exe "CFG Editor Project.csproj" -p:Configuration=Release
Pop-Location
Pop-Location

# build Pixi 64 bit
mkdir build
Push-Location build
cmake -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -G "Visual Studio 17 2022" -A x64 -S ..
cmake --build . --config Release --target pixi
Pop-Location

py -m pip install mistune bs4
py .\zip.py
Rename-Item pixi.zip pixi-x64.zip

Remove-Item -Recurse -Force build

# build Pixi 32 bit
mkdir build
Push-Location build
cmake -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -G "Visual Studio 17 2022" -A Win32 -S ..
cmake --build . --config Release --target pixi
Pop-Location

py .\zip.py
Rename-Item pixi.zip pixi-x86.zip