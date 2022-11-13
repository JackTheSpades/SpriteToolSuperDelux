import os
import zipfile
import re
import glob
import sys

def in_github_ci():
    val = os.getenv('GITHUB_ACTIONS', default='false')
    if val.lower() == 'true':
        return True
    else:
        return False

def asar_lib_name():
    if sys.platform == 'linux':
        return "libasar.so"
    elif sys.platform == 'win32':
        return "asar.dll"
    elif sys.platform == 'darwin':
        return "libasar.dylib"
    else:
        raise Exception("Unsupported platform: " + sys.platform)

def pixi_exe_name():
    if sys.platform == 'linux':
        return "pixi"
    elif sys.platform == 'win32':
        return "pixi.exe"
    elif sys.platform == 'darwin':
        return "pixi"
    else:
        raise Exception("Unsupported platform: " + sys.platform)

def isExcludeFile(path, excludes):
    if excludes is None:
        return False
    for item in excludes:
        if re.search(item, path.replace(os.sep, "/")):
            return True
    return False


def zipdir(path, ziph, excludes=None):
    # ziph is zipfile handle
    for root, _, files in os.walk(path):
        for file in files:
            if False == isExcludeFile(os.path.join(root, file), excludes):
                ziph.write(os.path.join(root, file))


def to_asm_folder(path):
    return os.path.join("asm", path)


if os.path.exists("pixi.zip"):
    os.remove("pixi.zip")

# *** what to exclude from routines (files starting with period)
def exclude_hidden(folder_name):
    return [r"^" + folder_name + r"/\."]


def keep_header_filter(folder_name):
    return [r"^" + folder_name + r"/(?!_header\.asm).+$"]


def keep_header_and_routine_filter(folder_name):
    return [r"^" + folder_name + r"/(?!(?:routines|_header)\.asm).+$"]


folder_filter_map = {
    "routines": exclude_hidden,
    "extended": keep_header_and_routine_filter,
}

# default filter = keep_header
def filter_for(folder_name):
    return folder_filter_map.get(folder_name, keep_header_filter)(folder_name)

def choose_binary(search_path):
    exes = glob.glob(search_path, recursive=True)
    if in_github_ci():
        return exes[0]
    if len(exes) > 1: 
        print("Found more than 1 binary: \n" + "\n".join((f'{i}: {p}' for i, p in enumerate(exes))))
        binnum = input("Input the number of the one to use: ")
        try:
            return exes[int(binnum)]
        except (ValueError, IndexError) as e:
            raise Exception("Error while choosing binary") from e
    elif len(exes) == 0:
        raise Exception(f"No binary found for {search_path}")
    else:
        return exes[0]

cfgexe = "src/CFG Editor/CFG Editor/bin/Release/CFG Editor.exe"
pixiexe = choose_binary(f'{os.getcwd()}{os.sep}**{os.sep}{pixi_exe_name()}')
asarlib = choose_binary(f'{os.getcwd()}{os.sep}**{os.sep}{asar_lib_name()}')

with zipfile.ZipFile("pixi.zip", "w", zipfile.ZIP_DEFLATED) as pixizip:

    for folder_name in [
        "sprites",
        "shooters",
        "generators",
        "cluster",
        "extended",
        "routines",
        "misc_sprites/bounce",
        "misc_sprites/minorextended",
        "misc_sprites/score",
        "misc_sprites/smoke",
        "misc_sprites/spinningcoin",
    ]:
        zipdir(folder_name, pixizip, filter_for(folder_name))

    # exe
    # add cfg editor only on windows
    if sys.platform == 'win32':
        pixizip.write(cfgexe.replace("/", os.sep), "CFG Editor.exe")
        pixizip.write(
            os.path.join(
                os.path.dirname(cfgexe.replace("/", os.sep)), "Newtonsoft.Json.dll"
            ),
            "Newtonsoft.Json.dll",
        )
    pixizip.write(pixiexe.replace("/", os.sep), pixi_exe_name())
    pixizip.write(asarlib.replace("/", os.sep), asar_lib_name())

    # asm
    for asm_folder_file in [
        "main.asm",
        "sa1def.asm",
        "cluster.asm",
        "extended.asm",
        "minorextended.asm",
        "score.asm",
        "bounce.asm",
        "spinningcoin.asm",
        "smoke.asm",
        "pointer_caller.asm",
        "DefaultSize.bin",
        "spritetool_clean.asm",
    ]:
        pixizip.write(to_asm_folder(asm_folder_file))

    # misc
    pixizip.write("README.html")
    pixizip.write("CHANGELOG.html")
    pixizip.write("CONTRIBUTING.html")
    pixizip.write("removedResources.txt")

print("pixi.zip created")
