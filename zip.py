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

def asm(path):
   return os.path.join('asm', path);

if os.path.exists('src.zip'):
   os.remove('src.zip')
if os.path.exists('pixi.zip'):
   os.remove('pixi.zip')
   
# *** This is the file list that excludes from src.zip 
src_excludes = [
        r"src/CFG Editor/.vs/.*",
        r"src/CFG Editor/.*/bin/.*",
        r"src/CFG Editor/.*/obj/.*",
        r".*\.gitignore\Z",
        r".*\.suo\Z",
        r".*\.user\Z"
        ]

# *** what to exclude from routines (files starting with period)
routine_excludes = [
        r"^routines/\."
        ]
        
with zipfile.ZipFile('src.zip', 'w') as srczip:
   zipdir('src', srczip, src_excludes)
   srczip.write('make.sh')
   srczip.write('make.bat')
   srczip.write('make_debug.bat')
print("src.zip created")

cfgexe = "src/CFG Editor/CFG Editor/bin/Release/CFG Editor.exe"

with zipfile.ZipFile('pixi.zip', 'w') as pixizip:

   #sprite dirs
   zipdir('sprites', pixizip)
   zipdir('shooters', pixizip)
   zipdir('generators', pixizip)
   zipdir('cluster', pixizip)
   zipdir('extended', pixizip)
   zipdir('routines', pixizip, routine_excludes)

   #exe
   pixizip.write(cfgexe.replace('/', os.sep), 'CFG Editor.exe');
   pixizip.write(
      os.path.join(
         os.path.dirname(cfgexe.replace('/', os.sep)),
         'Newtonsoft.Json.dll'), 
      'Newtonsoft.Json.dll');
   pixizip.write('pixi.exe')
   pixizip.write('asar.dll')
   
   #asm
   pixizip.write(asm('main.asm'))
   pixizip.write(asm('main_npl.asm'))
   pixizip.write(asm('sa1def.asm'))
   
   pixizip.write(asm('cluster.asm'))
   pixizip.write(asm('extended.asm'))
   pixizip.write(asm('pointer_caller.asm'))
      
   pixizip.write(asm('DefaultSize.bin'))
   
   zipdir(asm('Blocks'), pixizip)
   zipdir(asm('Converter Tools'), pixizip)
   pixizip.write(asm('Poison.asm'))
   
   #misc
   pixizip.write('src.zip')
   zipdir('Graphics for Included Sprites', pixizip)
   pixizip.write('readme.txt')   

print("pixi.zip created")
os.remove('src.zip')

            
