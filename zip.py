import os
import zipfile
import re
import glob
import requests
import shutil


def build_asar_dll(asar_ver):
    original_path = os.getcwd()
    url = f"https://github.com/RPGHacker/asar/archive/refs/tags/v{asar_ver}.zip"
    print(f"Downloading {url}")
    r = requests.get(url)
    with open("asar.zip", "wb") as f:
        f.write(r.content)
    print("Extracting asar.zip")
    with zipfile.ZipFile("asar.zip", "r") as zip_ref:
        zip_ref.extractall()
    os.remove("asar.zip")
    print("Building asar.dll")
    os.chdir(f"asar-{asar_ver}")
    os.mkdir("build")
    os.chdir("build")
    os.system("cmake -A x64 ../src")
    os.system("cmake --build . --config Release")
    asar_dll_path = glob.glob("**/asar.dll", recursive=True)[0]
    os.rename(asar_dll_path, os.path.join(original_path, "asar.dll"))
    os.chdir(original_path)
    shutil.rmtree(f"asar-{asar_ver}")


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


cfgexe = "src/CFG Editor/CFG Editor/bin/Release/CFG Editor.exe"
pixiexe = glob.glob('**/pixi.exe', recursive=True)[0]

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
    pixizip.write(cfgexe.replace("/", os.sep), "CFG Editor.exe")
    pixizip.write(
        os.path.join(
            os.path.dirname(cfgexe.replace("/", os.sep)), "Newtonsoft.Json.dll"
        ),
        "Newtonsoft.Json.dll",
    )
    pixizip.write(pixiexe.replace("/", os.sep), "pixi.exe")
    if not os.path.exists("asar.dll"):
        build_asar_dll("1.81")
    pixizip.write("asar.dll")

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
