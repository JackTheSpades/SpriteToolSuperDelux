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

# build latest pixi release along with zip and move in main directory
curl -s https://api.github.com/repos/JackTheSpades/SpriteToolSuperDelux/releases/latest | grep "tarball_url" | cut -d '"' -f 4 | wget -O latest.tar.gz -qi -
mkdir latest && tar xf latest.tar.gz -C latest --strip-components 1
rm latest.tar.gz
cp zip_pixi_rasp.py latest/zip_pixi_rasp.py
cd latest
spritecontents=$(cat src/sprite.cpp)
line=$'#include <vector>\n'
echo "$line$spritecontents" > src/sprite.cpp
make
mkdir build
mv pixi build/pixi
cd ..

# build asar 1.81
curl -s https://api.github.com/repos/RPGHacker/asar/releases/latest | grep "tarball_url" | cut -d '"' -f 4 | wget -O asar_latest.tar.gz -qi -
mkdir asar_latest && tar xf asar_latest.tar.gz -C asar_latest --strip-components 1
rm asar_latest.tar.gz
cd asar_latest
cmake src && make
cd ..

# move libasar.so in latest and build zip
cp asar_latest/asar/libasar.so latest/libasar.so
cd latest
python3 zip_pixi_rasp.py
mv pixi.zip ../pixi_latest.zip
cd ..

if [[ -z "${ARTIFACT_PATH}" ]]; then
    # clone current pixi repo and build zip
    CC=gcc-11
    CXX=g++-11
    git clone $repourl
    cp asar_latest/asar/libasar.so SpriteToolSuperDelux/libasar.so
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

# unzip both pixi zips (latest stable and current)
unzip pixi.zip -d pixi
unzip pixi_latest.zip -d pixi_latest

# delete temp files
rm -rf latest
rm -rf asar_latest
rm -rf SpriteToolSuperDelux
rm pixi.zip
rm pixi_latest.zip

mkdir downloader_test
cp downloader.py downloader_test/downloader.py

# move rom and start script
cp -r pixi downloader_test/pixi
mv downloader_test/pixi/pixi downloader_test/pixi/pixi_current
cp pixi_latest/pixi downloader_test/pixi/pixi_latest
cp base.smc downloader_test/pixi/base_current.smc
cp base.smc downloader_test/pixi/base_latest.smc
if [ -d ".sprites_dl_cache" ]; then
    cp -r .sprites_dl_cache/* downloader_test
    cd downloader_test 
    yes | python3 downloader.py "true"
    cd ..
else
    mkdir .sprites_dl_cache
    cd downloader_test 
    yes | python3 downloader.py "false"
    cd ..
    cp -r downloader_test/standard .sprites_dl_cache
    cp -r downloader_test/shooter .sprites_dl_cache
    cp -r downloader_test/generator .sprites_dl_cache
    cp -r downloader_test/cluster .sprites_dl_cache
    cp -r downloader_test/extended .sprites_dl_cache
fi

mv downloader_test/result_current.json result_current.json
mv downloader_test/result_latest.json result_latest.json
mv downloader_test/differences.json differences.json

rm -rf downloader_test
rm -rf pixi
rm -rf pixi_latest

# we have the json with the results
res=$(python3 check_diff.py)

# final clean up
rm result_current.json
rm result_latest.json
rm differences.json
rm base.smc