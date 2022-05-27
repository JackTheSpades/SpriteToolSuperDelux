import os
import zipfile
import re
import sys

def executable_name(name: str) -> str:
    if sys.platform == 'win32':
        return name + '.exe'
    elif sys.platform == 'linux':
        return name
    elif sys.platform == 'darwin':
        return name

def library_name(name: str) -> str:
    if sys.platform == 'win32':
        return name + '.dll'
    elif sys.platform == 'linux':
        return 'lib' + name + '.so'
    elif sys.platform == 'darwin':
        return 'lib' + name + '.dylib'

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
                try:
                    ziph.write(os.path.join(root, file))
                except Exception as e:
                    print(str(e))

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

pixiexe = executable_name("build/pixi")

os.rename(pixiexe, executable_name("pixi"))

with zipfile.ZipFile("pixi.zip", "w", zipfile.ZIP_DEFLATED) as pixizip:

    for folder_name in [
        "sprites",
        "shooters",
        "generators",
        "cluster",
        "extended",
        "misc_sprites/bounce",
        "misc_sprites/minorextended",
        "misc_sprites/score",
        "misc_sprites/smoke",
        "misc_sprites/spinningcoin",
        "routines",
    ]:
        zipdir(folder_name, pixizip, filter_for(folder_name))

    pixizip.write(executable_name("pixi"))
    pixizip.write(library_name("asar"))

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
        try:
            pixizip.write(to_asm_folder(asm_folder_file))
        except Exception as e:
            print(str(e))
    # misc
    pixizip.write("readme.txt")
    pixizip.write("changelog.txt")
    pixizip.write("removedResources.txt")

print("pixi.zip created")
