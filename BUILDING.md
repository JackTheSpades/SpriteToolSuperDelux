# Building Pixi

## Prerequisites
- CMake 3.18 or newer.
- Python 3.10 or newer.
- (Test suite only | Linux only) `unzip` (can be installed with `sudo apt install unzip` on Ubuntu)
- (Test suite only) The `requests` and `beatifulsoup4` Python modules.

### Windows
- Visual Studio 2022 with the C++ workload installed or MinGW-w64

### Linux
- Clang 14+ or GCC 13+.

### MacOS
- AppleClang 14+

## Steps

I know that there are 2 scripts (`build_script.ps1`/`build_script.sh`) that may seem tempting to use to build the project, however those are specifically used just for automated CI and they assume a lot about the environment they are running in. It is recommended instead to use the steps below to build the project. 

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