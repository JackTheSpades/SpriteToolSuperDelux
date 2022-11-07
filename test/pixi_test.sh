# download base file
argc=$#

if [ "$argc" -eq "2" ]; then
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
    repourl="https://github.com/JackTheSpades/SpriteToolSuperDelux"
elif [ "$repotype" = "local" ]; then
    echo "Using local repository"
    repourl=".. SpriteToolSuperDelux"
else
    echo "Wrong repository type"
    exit 1
fi

wget www.atarismwc.com/base.smc

if [[ -z "${ARTIFACT_PATH}" ]]; then
    # clone current pixi repo and build zip
    CC=gcc-11
    CXX=g++-11
    git clone $repourl
    cd SpriteToolSuperDelux
    git checkout $branch
    mkdir build
    cd build
    cmake .. && make
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
cp EXPECTED.lst downloader_test/EXPECTED.lst

# move rom and start script
cp -r pixi downloader_test/pixi
cp base.smc downloader_test/pixi/base.smc
if [ -d ".sprites_dl_cache" ]; then
    cp -r .sprites_dl_cache/* downloader_test
    cd downloader_test 
    yes | python3 runner.py "true"
    cd ..
else
    mkdir .sprites_dl_cache
    cd downloader_test
    if [[ "$OSTYPE" != "darwin"* ]]; then
        yes | python3 runner.py "false"
    else
        python3 runner.py "false"
    fi
    echo "Finished testing all sprites"
    cd ..
    if [[ "$OSTYPE" != "darwin"* ]]; then
        cp -r downloader_test/standard .sprites_dl_cache
        cp -r downloader_test/shooter .sprites_dl_cache
        cp -r downloader_test/generator .sprites_dl_cache
        cp -r downloader_test/cluster .sprites_dl_cache
        cp -r downloader_test/extended .sprites_dl_cache
     fi
fi

echo "Moving results"
mv downloader_test/result.json result.json

echo "Deleting temp files"
rm -rf downloader_test
rm -rf pixi
rm base.smc
