#!/bin/bash
# download base file
argc=$#

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
    repourl=(".. SpriteToolSuperDelux")
else
    echo "Wrong repository type"
    exit 1
fi

wget www.atarismwc.com/base.smc

if [[ -z "${ARTIFACT_PATH}" ]]; then
    # clone current pixi repo and build zip
    git clone "${repourl[@]}"
    cd SpriteToolSuperDelux || exit
    git checkout "$branch"
    mkdir build
    cd build || exit
    cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release
    cmake --build . --target pixi
    cd ..
    python3 zip.py
    mv pixi.zip ../pixi.zip
    cd ..
else
    cp "${ARTIFACT_PATH}" pixi.zip
fi

unzip pixi.zip -d pixi

# delete temp files
if [[ -z "${ARTIFACT_PATH}" ]]; then
    rm -rf SpriteToolSuperDelux
fi
rm pixi.zip

mkdir downloader_test
cp runner.py downloader_test/runner.py
cp downloader.py downloader_test/downloader.py
cp EXPECTED.lst downloader_test/EXPECTED.lst

# move rom and start script
cp -r pixi downloader_test/pixi
cp base.smc downloader_test/pixi/base.smc
# check if directory exists and is not empty
if [ -d ".sprites_dl_cache" ] && [ -n "$(ls -A .sprites_dl_cache)" ]; then
    cp -r .sprites_dl_cache/* downloader_test
    cd downloader_test || exit 
    if [[ "$justSetup" == "false" ]]; then
        if [[ "$OSTYPE" != "darwin"* ]]; then
            yes | python3 runner.py --cached
        else
            python3 runner.py --cached
        fi
        echo "Finished testing all sprites"
    fi
    cd ..
else
    mkdir .sprites_dl_cache
    cd downloader_test || exit
    if [[ "$justSetup" == "false" ]]; then
        if [[ "$OSTYPE" != "darwin"* ]]; then
            yes | python3 runner.py
        else
            python3 runner.py
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

    echo "Deleting temp files"
    rm -rf downloader_test
    rm -rf pixi
    rm base.smc
fi