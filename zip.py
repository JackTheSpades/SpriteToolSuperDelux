#!/usr/bin/python

import os
import zipfile
import re

def isExcludeFile(path, excludes):
    if excludes is None:
        return False
    for item in excludes:
        if re.search(item, path.replace(os.sep, '/')):
           return True
    return False

def zipdir(path, ziph, excludes=None):
   # ziph is zipfile handle
   for root, dirs, files in os.walk(path):
      for file in files:
         if False == isExcludeFile(os.path.join(root, file), excludes):
            ziph.write(os.path.join(root, file))

def to_asm_folder(path):
   return os.path.join('asm', path);

if os.path.exists('pixi.zip'):
   os.remove('pixi.zip')

# *** what to exclude from routines (files starting with period)
def exclude_hidden(folder_name):
	return [r"^" + folder_name + r"/\."]

def keep_header_filter(folder_name):
	return [r"^" + folder_name + r"/(?!_header\.asm).+$"]
	
def keep_header_and_routine_filter(folder_name):
	return [r"^" + folder_name + r"/(?!(?:routines|_header)\.asm).+$"]

folder_filter_map = {
	'routines': exclude_hidden,
	'extended': keep_header_and_routine_filter,
}

# default filter = keep_header
def filter_for(folder_name):
	return folder_filter_map.get(folder_name, keep_header_filter)(folder_name)

cfgexe = "src/CFG Editor/CFG Editor/bin/Release/CFG Editor.exe"

with zipfile.ZipFile('pixi.zip', 'w', zipfile.ZIP_DEFLATED) as pixizip:

   for folder_name in ['sprites', 'shooters', 'generators', 'cluster', 'extended', 'routines']:
      zipdir(folder_name, pixizip, filter_for(folder_name))

   #exe
   pixizip.write(cfgexe.replace('/', os.sep), 'CFG Editor.exe')
   pixizip.write(
      os.path.join(
         os.path.dirname(cfgexe.replace('/', os.sep)),
         'Newtonsoft.Json.dll'), 
      'Newtonsoft.Json.dll')
   pixizip.write('pixi.exe')
   pixizip.write('asar.dll')
   
   #asm
   for asm_folder_file in ['main.asm', 'sa1def.asm', 'cluster.asm', 'extended.asm', 'pointer_caller.asm', 'DefaultSize.bin', 'spritetool_clean.asm']:
      pixizip.write(to_asm_folder(asm_folder_file))
   
   #misc
   pixizip.write('readme.txt')
   pixizip.write('changelog.txt')
   pixizip.write('removedResources.txt')

print("pixi.zip created")

            
