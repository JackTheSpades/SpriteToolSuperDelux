# download base file
wget www.atarismwc.com/base.smc

# build latest pixi release along with zip and move in main directory
curl -s https://api.github.com/repos/JackTheSpades/SpriteToolSuperDelux/releases/latest | grep "tarball_url" | cut -d '"' -f 4 | wget -O latest.tar.gz -qi -
mkdir latest && tar xf latest.tar.gz -C latest --strip-components 1
rm latest.tar.gz
cp zip_pixi_rasp.py latest/zip_pixi_rasp.py
cd latest
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

# clone current pixi repo and build zip
git clone https://github.com/JackTheSpades/SpriteToolSuperDelux 
cp asar_latest/asar/libasar.so SpriteToolSuperDelux/libasar.so
cp zip_pixi_rasp.py SpriteToolSuperDelux/zip_pixi_rasp.py
cd SpriteToolSuperDelux
mkdir build
cd build
cmake .. && make
cd ..
python3 zip_pixi_rasp.py
mv pixi.zip ../pixi.zip
cd ..

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
cd downloader_test
yes | python3 downloader.py
cd ..
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