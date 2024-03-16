function PackagePixi {
    param(
        [string]$Arch = "x64"
    )

    Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue

    # build CFG Editor first
    Push-Location "src/CFG Editor"
    Push-Location "CFG Editor"
    Remove-Item -Recurse -Force "bin/Release/net8.0-windows" -ErrorAction SilentlyContinue
    dotnet publish --nologo -p:PublishSingleFile=true --sc false -r win-$Arch -c Release -f net8.0-windows -o "bin/Release/net8.0-windows"
    Pop-Location
    Pop-Location

    $CmakeArch = "x64"
    if ($Arch -eq "x86") {
        $CmakeArch = "Win32"
    }

    # build pixi
    mkdir build
    Push-Location build
    cmake -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -G "Visual Studio 17 2022" -A $CmakeArch -S ..
    cmake --build . --config Release --target pixi
    Pop-Location

    # zip
    py .\zip.py
    Rename-Item pixi.zip "pixi-windows-$Arch.zip"
}

py -m pip install mistune bs4
PackagePixi -Arch "x64"
PackagePixi -Arch "x86"