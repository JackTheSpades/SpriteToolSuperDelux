mkdir build
cd build
cmake -G "Unix Makefiles" -DPIXI_BUILD_TESTS=OFF -DPIXI_BUILD_DLL=OFF -DPIXI_BUILD_LIB=OFF -DCMAKE_BUILD_TYPE=Release -S ..
make -j $(nproc)
cd ..
python3 -m pip install mistune bs4
python3 zip.py