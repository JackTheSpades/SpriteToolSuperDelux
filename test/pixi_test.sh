#!/bin/bash
# download base file
argc=$#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet mistune beautifulsoup4 requests libretro.py pillow
fi

PYTHON="$VENV_DIR/bin/python3"

if [ "$argc" -ge "4" ]; then
    emuFlag="--emu"
else
    emuFlag=""
fi

if [ "$argc" -ge "3" ]; then
    justSetup=$3
else
    justSetup="false"
fi

if [ "$argc" -ge "2" ]; then
    repotype=$2
else
    repotype="remote"
fi

if [ "$argc" -lt "1" ]; then
    echo "Using master branch"
    branch="master"
else
    echo "Using $1 branch"
    branch=$1
fi

if [ "$repotype" = "remote" ]; then
    echo "Using remote repository"
    repourl=("https://github.com/JackTheSpades/SpriteToolSuperDelux")
elif [ "$repotype" = "local" ]; then
    echo "Using local repository"
    repourl=(".." "SpriteToolSuperDelux")
else
    echo "Wrong repository type"
    exit 1
fi

export PIXI_TESTING="true"
wget www.atarismwc.com/base.smc

if [[ -z "${ARTIFACT_PATH}" ]]; then
    # clone current pixi repo and build zip
    git clone "${repourl[@]}"
    cd SpriteToolSuperDelux || exit
    git checkout "$branch"
    mkdir build
    cd build || exit
    cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release -DPIXI_BUILD_TESTS=OFF
    cmake --build . --target pixi --parallel
    cmake --build . --target pixi_api --parallel
    cd ..
    $PYTHON zip.py
    mv pixi.zip ../pixi.zip
    cd ..
else
    cp "${ARTIFACT_PATH}" pixi.zip
fi

unzip pixi.zip -d pixi
cp  SpriteToolSuperDelux/src/api_bindings/pixi_api.py pixi/pixi_api.py

mkdir downloader_test
cp runner.py downloader_test/runner.py
cp downloader.py downloader_test/downloader.py
cp EXPECTED.lst downloader_test/EXPECTED.lst

cp -r pixi downloader_test/pixi
cp base.smc downloader_test/pixi/base.smc

wget www.atarismwc.com/testing.smc
$LIBRETRO_LIB_ZIP=""
if [[ "$OSTYPE" != "darwin"* ]]; then
    wget https://buildbot.libretro.com/nightly/linux/x86_64/latest/snes9x_libretro.so.zip
    unzip  snes9x_libretro.so.zip -d .
    mv    snes9x_libretro.so downloader_test/snes9x_libretro.so
    $LIBRETRO_LIB_ZIP="snes9x_libretro.so.zip"
else
    wget https://buildbot.libretro.com/nightly/osx/x86_64/latest/snes9x_libretro.dylib.zip
    unzip  snes9x_libretro.dylib.zip -d .
    mv    snes9x_libretro.dylib downloader_test/snes9x_libretro.dylib
    $LIBRETRO_LIB_ZIP="snes9x_libretro.dylib.zip"
fi
mv    testing.smc        downloader_test/pixi/testing.smc
cp    emulator.py        downloader_test/emulator.py
cp    asar.py            downloader_test/asar.py

# delete temp files
if [[ -z "${ARTIFACT_PATH}" ]]; then
    rm -rf SpriteToolSuperDelux
fi
rm pixi.zip

# check if directory exists and is not empty
if [ -d ".sprites_dl_cache" ] && [ -n "$(ls -A .sprites_dl_cache)" ]; then
    cp -r .sprites_dl_cache/* downloader_test
    cd downloader_test || exit 
    if [[ "$justSetup" == "false" ]]; then
        if [[ "$OSTYPE" != "darwin"* ]]; then
            yes | $PYTHON runner.py --cached $emuFlag
        else
            $PYTHON runner.py --cached $emuFlag
        fi
        echo "Finished testing all sprites"
    fi
    cd ..
else
    mkdir .sprites_dl_cache
    cd downloader_test || exit
    if [[ "$justSetup" == "false" ]]; then
        if [[ "$OSTYPE" != "darwin"* ]]; then
            yes | $PYTHON runner.py $emuFlag
        else
            $PYTHON runner.py $emuFlag
        fi
        echo "Finished testing all sprites"
    fi
    cd ..
    if [[ "$OSTYPE" != "darwin"* ]]; then
        cp -r downloader_test/standard .sprites_dl_cache
        cp -r downloader_test/shooter .sprites_dl_cache
        cp -r downloader_test/generator .sprites_dl_cache
        cp -r downloader_test/cluster .sprites_dl_cache
        cp -r downloader_test/extended .sprites_dl_cache
     fi
fi

if [[ "$justSetup" == "false" ]]; then
    echo "Moving results"
    if [[ -f "downloader_test/diffs.txt" ]]; then
        mv downloader_test/diffs.txt diffs.txt
    fi
    mv downloader_test/result.json result.json
    if [[ -d "downloader_test/screenshots" ]]; then
        mv downloader_test/screenshots screenshots
    fi

    echo "Deleting temp files"
    rm -rf downloader_test
    rm -rf pixi
    rm base.smc
    rm $LIBRETRO_LIB_ZIP
    rm -rf .venv
fi