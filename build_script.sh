#!/bin/bash
set -e 

ASAR_TYPE="lib"

if [[ -n "$1" ]]; then
    if [[ "$1" == "dll" || "$1" == "lib" ]]; then
        ASAR_TYPE="$1"
    else
        echo "Error: Invalid argument '$1'. Allowed values are 'dll' or 'lib'."
        exit 1
    fi
fi

if [[ "$ASAR_TYPE" == "dll" ]]; then
    CMAKE_ASAR_USE_DLL="ON"
    PYTHON_ARGS=""
else
    CMAKE_ASAR_USE_DLL="OFF"
    PYTHON_ARGS="--static"
fi

OS_NAME=$(uname -s)
COMPILER_FLAGS=""
ZIP_SUFFIX=""
CPU_CORES=1

if [[ "$OS_NAME" == "Linux" ]]; then
    ZIP_SUFFIX="linux-x64"
elif [[ "$OS_NAME" == "Darwin" ]]; then
    ZIP_SUFFIX="macos-x64"
else
    echo "Unsupported OS: $OS_NAME"
    exit 1
fi

mkdir -p build
cd build

cmake -DASAR_USE_DLL=$CMAKE_ASAR_USE_DLL \
      $COMPILER_FLAGS \
      -DPIXI_BUILD_TESTS=OFF \
      -DPIXI_BUILD_DLL=OFF \
      -DPIXI_BUILD_LIB=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -S ..

cmake --build . --target pixi --config MinSizeRel --parallel

cd ..

python3 -m pip install mistune bs4
python3 zip.py $PYTHON_ARGS

mv pixi.zip "pixi-${ZIP_SUFFIX}.zip"