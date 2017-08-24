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
g++ $CFLAGS -o "pixi" -Wall --std=c++11 -Wno-format $LDFLAGS src/*.cpp src/asar/asardll.c
#@pause
