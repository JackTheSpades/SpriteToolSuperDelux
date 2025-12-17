param (
	[ValidateSet("dll", "lib")]
	[string]$AsarType = "lib"
)

# build CFG Editor first

if ($AsarType -eq "dll") {
	$CMAKE_ASAR_USE_DLL = "ON"
	$PYTHON_OPTIONS = @()
} else {
	$CMAKE_ASAR_USE_DLL = "OFF"
	$PYTHON_OPTIONS = @("--static")
}

Push-Location "src/CFG Editor"
nuget restore "CFG Editor.sln"
Push-Location "CFG Editor"
dotnet restore
msbuild.exe "CFG Editor Project.csproj" -p:Configuration=Release
Pop-Location
Pop-Location

Remove-Item -Recurse -Force build

# build Pixi 64 bit
mkdir build
Push-Location build
cmake -DASAR_USE_DLL="$CMAKE_ASAR_USE_DLL" -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -G "Visual Studio 17 2022" -A x64 -S ..
cmake --build . --config MinSizeRel --target pixi
Pop-Location

py -m pip install mistune bs4
py .\zip.py @PYTHON_OPTIONS
Remove-Item pixi-windows-x64.zip -ErrorAction SilentlyContinue
Rename-Item -Force pixi.zip pixi-windows-x64.zip

Remove-Item -Recurse -Force build

# build Pixi 32 bit
mkdir build
Push-Location build
cmake -DASAR_USE_DLL="$CMAKE_ASAR_USE_DLL" -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -G "Visual Studio 17 2022" -A Win32 -S ..
cmake --build . --config MinSizeRel --target pixi
Pop-Location

py .\zip.py @PYTHON_OPTIONS
Remove-Item pixi-windows-x86.zip -ErrorAction SilentlyContinue
Rename-Item -Force pixi.zip pixi-windows-x86.zip