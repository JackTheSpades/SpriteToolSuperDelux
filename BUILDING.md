# Building Pixi

## Prerequisites
- CMake 3.18 or newer.
- Python 3.10 or newer.
- (Test suite only | Linux only) `unzip` (can be installed with `sudo apt install unzip` on Ubuntu)
- (Test suite only) The `requests` and `beatifulsoup4` Python modules.

### Windows
- Visual Studio 2022 with the C++ workload installed or MinGW-w64, plus the C# workload if you want to build the CFG Editor.

### Linux
- Clang 14+ or GCC 13+.

### MacOS
- AppleClang 14+

## Build scripts
There are the 2 build scripts (`build_script.ps1`, `build_script.sh`) that can be used to build the project, but if you want to do it manually, follow the steps below.

The build scripts require the following to complete successfully:
- CMake 3.18+
- Python 3.10+, with the beatifulsoup4 and mistune modules installed, the build script will attempt to install them automatically if they are missing.
- WINDOWS ONLY: Visual Studio 2022 with the C++ and the C# workloads installed
- WINDOWS ONLY: the script needs to be ran from a Developer PowerShell for VS 2022.
- LINUX ONLY: GCC 13+ or Clang 14+
- MACOS ONLY: AppleClang 14+

The scripts will create a `build` folder in the repository and place all the build files there.
After the build is done, there will be 1 or 2 zips created in the repository folder, one with the Pixi 64 bit release build and one with Pixi 32 bit release build (Windows only).

## Steps

### Windows
With Visual Studio, simply open the repository in VS, let it configure the project and then hit the `Build All` button.

This is the preferred building method and by far the easiest. 

To add a new configuration add it from the dropdown menu near the `Windows x64 Debug (cl)` label at the top of VS and then press `Manage Configurations`, from there, you can add whatever configuration you prefer, there should be a fair few already pre-made ones. 

The new configuration will already have all the necessary compiler/linker options and all the defines already set up.

Alternatively, if you don't want to use a GUI, but still want to use Microsoft compiler, you can do so by doing:
```
mkdir build
cd build
cmake -S ..
cmake --build . --config <config>
```
from a command line while inside of the repository's folder.

Replace `<config>` with one of the configurations: `Debug`, `Release`, `RelWithDebInfo` or `MinSizeRel`. 

However just keep in mind that this step still requires you to have Visual Studio installed.

If you decide to use MinGW-w64 instead, you'll need to run from a command line:
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
To build the CFG Editor, you'll simply need Visual Studio 2022 with the C# workload installed. Open the repository in VS, configure and build the solution.