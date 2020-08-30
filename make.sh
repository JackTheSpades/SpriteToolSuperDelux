#### -----------------------------------
# make script for unix
#### -----------------------------------

#### --- compile option
CFLAGS="-O2 -s -ffunction-sections -fdata-sections -Wl,--gc-sections"
LDFLAGS="-L. -lasar -ldl"
#### -----------------------------------

#### libasar.so check
if test ! -e libasar.so ; then
	echo "Error: \"libasar.so\" is missing."
	exit
fi

#### compile
g++ $CFLAGS -o "pixi" -fpermissive -Wall --std=c++11 -Wno-format src/*.cpp src/asar/asardll.c src/MeiMei/*.cpp src/json/base64.cpp -ldl
#@pause
