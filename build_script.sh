mkdir build
cd build
if [[ "$APPVEYOR_BUILD_WORKER_IMAGE" == "Ubuntu2204" ]]; then
	cmake -DASAR_USE_DLL=OFF -DCMAKE_C_COMPILER=gcc-13 -DCMAKE_CXX_COMPILER=g++-13 -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -DCMAKE_BUILD_TYPE=Release -S ..
else
	cmake -DASAR_USE_DLL=OFF -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -DCMAKE_BUILD_TYPE=Release -S ..
fi
cmake --build . --target pixi --config MinSizeRel --parallel $(nproc)
cd ..
python3 -m pip install mistune bs4
python3 zip.py --static
if [[ "$APPVEYOR_BUILD_WORKER_IMAGE" == "Ubuntu2204" ]]; then
	mv pixi.zip pixi-linux-x64.zip
elif [[ "$APPVEYOR_BUILD_WORKER_IMAGE" == "macOS-Sonoma" ]]; then
	mv pixi.zip pixi-macos-x64.zip
fi