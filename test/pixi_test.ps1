# download base file
$argc = $args.Count

if ( $argc -eq 2 ) {
    $repotype = $args[1]
}
else {
    $repotype = "remote"
}

if ( $argc -lt 1 ) {
    $branch = "master"
    Write-Output "Using master branch"
}
else {
    $branch = $args[0]
    Write-Output "Using $branch branch"
}

if ( $repotype -eq "remote" ) {
    Write-Output "Using remote repository"
    $repourl = @("https://github.com/JackTheSpades/SpriteToolSuperDelux")
}
elseif ( $repotype -eq "local" ) {
    Write-Output "Using local repository"
    $repourl = @('..', 'SpriteToolSuperDelux')
}
else {
    Write-Output "Wrong repository type"
    exit 1
}

Invoke-WebRequest -Uri www.atarismwc.com/base.smc -OutFile base.smc

function unzip_and_move {
    param ( [string]$zipfile, [string]$outdir )
    mkdir $outdir
    unzip -qq $zipfile -d $outdir
    Set-Location $outdir
    $folder = Get-ChildItem
    Move-Item -Path $folder\* -Destination . -Force
    Remove-Item $folder
    Set-Location ..
}

# build latest pixi release along with zip and move in main directory
Invoke-WebRequest -Uri (curl -s https://api.github.com/repos/JackTheSpades/SpriteToolSuperDelux/releases/latest | grep "zipball_url").split('"')[3] -OutFile latest.zip
unzip_and_move "latest.zip" "latest"
Remove-Item latest.zip
Copy-Item zip_pixi_rasp.py latest/zip_pixi_rasp.py
Set-Location latest
$spritecontents = (Get-Content src/sprite.cpp -Raw)
$line = "#include <vector>`n"
$line + $spritecontents | Set-Content src/sprite.cpp
(Get-Content .\make.bat -Raw).Replace("-m32", "").Replace("src/icon.res", "").Replace("@pause", "") | Set-Content .\make.bat 
.\make.bat
mkdir build
Move-Item pixi.exe build/pixi.exe
Set-Location ..

# build asar 1.81
Invoke-WebRequest -Uri (curl -s https://api.github.com/repos/RPGHacker/asar/releases/latest | findstr "zipball_url").split('"')[3] -OutFile asar_latest.zip
unzip_and_move "asar_latest.zip" "asar_latest"
Remove-Item asar_latest.zip
Set-Location asar_latest
cmake -A x64 src
cmake --build . --config MinSizeRel
Set-Location ..

# move libasar.so in latest and build zip
Copy-Item asar_latest/asar/MinSizeRel/asar.dll latest/asar.dll
Set-Location latest
py zip_pixi_rasp.py
Move-Item pixi.zip ../pixi_latest.zip
Set-Location ..

# clone current pixi repo and build zip
if ($env:ARTIFACT_PATH) {
    $artifact_path = $env:ARTIFACT_PATH
    Move-Item $artifact_path pixi.zip
} else {
    git clone $repourl
    Set-Location SpriteToolSuperDelux
    git checkout $branch
    Set-Location ..
    Copy-Item asar_latest/asar/MinSizeRel/asar.dll SpriteToolSuperDelux/asar.dll
    Set-Location SpriteToolSuperDelux
    mkdir build
    Set-Location build
    cmake ..
    cmake --build . --config Release
    Set-Location ..
    $cont = Get-Content zip.py
    $newcont = $cont[0..96] + $cont[105..($cont.Length-1)]
    Set-Content $newcont -Path zip.py
    py zip.py
    Move-Item pixi.zip ../pixi.zip
    Set-Location ..
}

# unzip both pixi zips (latest stable and current)
unzip pixi.zip -d pixi
unzip pixi_latest.zip -d pixi_latest

# delete temp files
Remove-Item -Recurse -Force latest
Remove-Item -Recurse -Force asar_latest
Remove-Item -Recurse -Force SpriteToolSuperDelux
Remove-Item pixi.zip
Remove-Item pixi_latest.zip

mkdir downloader_test
Copy-Item downloader.py downloader_test/downloader.py

# move rom and start script
Copy-Item -Recurse pixi downloader_test
Copy-Item downloader_test/pixi/pixi.exe downloader_test/pixi/pixi_current.exe
Copy-Item pixi_latest/pixi.exe downloader_test/pixi/pixi_latest.exe
Copy-Item base.smc downloader_test/pixi/base_current.smc
Copy-Item base.smc downloader_test/pixi/base_latest.smc
if (Test-Path -Path ".sprites_dl_cache") {
    Copy-Item -Recurse -Path .sprites_dl_cache/* -Destination downloader_test
    Set-Location downloader_test
    py downloader.py "true"
    Set-Location ..
}
else {
    mkdir .sprites_dl_cache
    Set-Location downloader_test 
    py downloader.py "false"
    Set-Location ..
    Copy-Item -Recurse downloader_test/standard .sprites_dl_cache
    Copy-Item -Recurse downloader_test/shooter .sprites_dl_cache
    Copy-Item -Recurse downloader_test/generator .sprites_dl_cache
    Copy-Item -Recurse downloader_test/cluster .sprites_dl_cache
    Copy-Item -Recurse downloader_test/extended .sprites_dl_cache
}

Move-Item downloader_test/result_current.json result_current.json
Move-Item downloader_test/result_latest.json result_latest.json
Move-Item downloader_test/differences.json differences.json

Remove-Item -Recurse -Force downloader_test
Remove-Item -Recurse -Force pixi
Remove-Item -Recurse -Force pixi_latest

# we have the json with the results
py check_diff.py

# final clean up
Remove-Item result_current.json
Remove-Item result_latest.json
Remove-Item differences.json
Remove-Item base.smc