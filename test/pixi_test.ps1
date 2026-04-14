param(
    [Parameter(Mandatory=$false)]
    [string]$Branch = "master",
    [Parameter(Mandatory=$false)]
    [ValidateSet("remote", "local")]
    [string]$RepoType = "remote",
    [Parameter(Mandatory=$false)]
    [bool]$JustSetup = $false,
    [switch]$Emu
)

$env:PIXI_TESTING = "true"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$venvDir = Join-Path $scriptDir ".venv"
if (-not (Test-Path -Path $venvDir)) {
    py -m venv $venvDir
    & $venvDir\Scripts\pip.exe install --quiet mistune beautifulsoup4 requests libretro.py pillow
}

$pythonExecutable = Join-Path $venvDir "Scripts\python.exe"

if ($JustSetup) {
    if ((Test-Path -Path ".sprites_dl_cache") -and (Test-Path -Path ".sprites_dl_cache\*")) {
        Write-Output "Just running setup"
    } else {
        Write-Output "Cannot run just setup without cached sprites, aborting..."
        exit 1
    }
} else {
    Write-Output "Running full test"
}

Write-Output "Using $Branch branch"

if ( $RepoType -eq "remote" ) {
    Write-Output "Using remote repository"
    $repourl = @("https://github.com/JackTheSpades/SpriteToolSuperDelux")
}
elseif ( $RepoType -eq "local" ) {
    Write-Output "Using local repository"
    $repourl = @('..', 'SpriteToolSuperDelux')
}
else {
    Write-Output "Wrong repository type"
    exit 1
}

Invoke-WebRequest -Uri www.atarismwc.com/base.smc -OutFile base.smc

# clone current pixi repo and build zip
if ($env:ARTIFACT_PATH) {
    $artifact_path = $env:ARTIFACT_PATH
    Move-Item $artifact_path pixi.zip
} else {
    git clone $repourl
    Set-Location SpriteToolSuperDelux
    git checkout $Branch
    mkdir build
    Set-Location build
    cmake .. -DPIXI_BUILD_TESTS=OFF
    cmake --build . --config Release --target pixi --parallel
    cmake --build . --config Release --target pixi_api --parallel
    Set-Location ..
    & $pythonExecutable zip.py
    Move-Item pixi.zip ../pixi.zip
    Set-Location ..
}

Expand-Archive pixi.zip -DestinationPath pixi
Copy-Item ../src/api_bindings/pixi_api.py pixi/pixi_api.py

mkdir downloader_test
Copy-Item runner.py downloader_test/runner.py
Copy-Item downloader.py downloader_test/downloader.py
Copy-Item EXPECTED.lst downloader_test/EXPECTED.lst

# move rom and start script
Copy-Item -Recurse pixi downloader_test
Copy-Item base.smc downloader_test/pixi/base.smc

Invoke-WebRequest -Uri www.atarismwc.com/testing.smc -OutFile testing.smc
Invoke-WebRequest -Uri https://buildbot.libretro.com/nightly/windows/x86_64/latest/snes9x_libretro.dll.zip -OutFile snes9x_libretro.dll.zip
Expand-Archive snes9x_libretro.dll.zip -DestinationPath .
Move-Item snes9x_libretro.dll downloader_test/snes9x_libretro.dll
Move-Item testing.smc downloader_test/pixi/testing.smc
Copy-Item emulator.py downloader_test/emulator.py
Copy-Item asar.py downloader_test/asar.py


# delete temp files
if (!$env:ARTIFACT_PATH) {
    Remove-Item -Recurse -Force SpriteToolSuperDelux
}
Remove-Item pixi.zip

# this if check makes sure that .sprites_dl_cache exists and is not empty
if ((Test-Path -Path ".sprites_dl_cache") -and (Test-Path -Path ".sprites_dl_cache\*")) {
    Copy-Item -Recurse -Path .sprites_dl_cache/* -Destination downloader_test
    Set-Location downloader_test
    if (-not $JustSetup) {
        if ($Emu.IsPresent) {
            & $pythonExecutable runner.py --cached --emu
        } else {
            & $pythonExecutable runner.py --cached
        }
    }
    Set-Location ..
}
else {
    mkdir .sprites_dl_cache
    Set-Location downloader_test 
    if (-not $JustSetup) {
        if ($Emu.IsPresent) {
            & $pythonExecutable runner.py --emu
        } else {
            & $pythonExecutable runner.py
        }
    }
    Set-Location ..
    Copy-Item -Recurse downloader_test/standard .sprites_dl_cache
    Copy-Item -Recurse downloader_test/shooter .sprites_dl_cache
    Copy-Item -Recurse downloader_test/generator .sprites_dl_cache
    Copy-Item -Recurse downloader_test/cluster .sprites_dl_cache
    Copy-Item -Recurse downloader_test/extended .sprites_dl_cache
}
if (-not $JustSetup) {
    Move-Item -Force downloader_test/result.json result.json
    if (Test-Path -Path downloader_test/diffs.txt) {
        Move-Item -Force downloader_test/diffs.txt diffs.txt
    }
    if (Test-Path -Path downloader_test/screenshots) {
         Move-Item -Force downloader_test/screenshots screenshots
    }
    Remove-Item -Recurse -Force downloader_test
    Remove-Item -Recurse -Force pixi
    Remove-Item base.smc
    Remove-Item snes9x_libretro.dll.zip
    Remove-Item -Recurse -Force .venv
}