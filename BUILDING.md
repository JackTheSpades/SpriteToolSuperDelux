# Building Pixi

## Prerequisites
- CMake 3.18 or newer.
- Python 3.8 or newer.
- (Test suite only) `requests` and `beatifulsoup4` Python modules installed.

### Windows
- Visual Studio 2019/2022 with the C++ workload installed or MinGW-w64

### Linux
- Clang 13+ or GCC 11+.

### MacOS
- AppleClang 13+

## Steps

### Windows
With Visual Studio, simply open the repository in VS, configure and build the solution.

If you're using MinGW-w64, you'll need to run from a command line:
```
mkdir build
cd build
cmake -S .. -G "MinGW Makefiles"
mingw32-make
``` 
in the folder where you cloned the repository. This assumes you have added MinGW-w64 to your PATH.

### Linux
Simply run 
```
mkdir build
cd build
cmake -S .. -B .
cmake --build . --config <config>
```
from a command line while inside of the repository's folder.
Replace `<config>` with one of the configurations: `Debug`, `Release`, `RelWithDebInfo` or `MinSizeRel`

### MacOS
Open the repository in Xcode and let it configure the project for you.
Then, build the project.

Or run the same steps as the Linux build.

## Result:
Doing these steps will result in the build of both the pixi executable and the PixiUnitTests executable. To run the unittests, simply run the PixiUnitTests executable, to run the more extensive test suite, go into the `test` folder and run `pixi_test.ps1` (windows) or `pixi_test.sh` (linux/macos).

# Building CFG Editor

## Windows only
To build the CFG Editor, you'll simply need Visual Studio 2019/2022 with the C# workload installed. Open the repository in VS, configure and build the solution.