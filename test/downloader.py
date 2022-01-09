import requests
from bs4 import BeautifulSoup
import os
from contextlib import suppress
import json
from urllib import parse
import glob
from zipfile import ZipFile
from shutil import copyfile, rmtree, copytree
import subprocess
import re
import traceback

types = {
    'standard': (46, 14),
    'shooter': (47, 1),
    'generator': (48, 1),
    'cluster': (64, 1),
    'extended': (65, 1),
}

list_types = {
    'standard': ('SPRITE:', 0),
    'shooter': ('SPRITE:', 0xC0),
    'generator': ('SPRITE:', 0xD0),
    'cluster': ('CLUSTER:', 0),
    'extended': ('EXTENDED:', 0)
}


def download():
    with requests.Session() as sess:
        for name, value in types.items():
            with suppress(Exception):
                os.mkdir(name)
            nameids = {}
            spid, pages = value
            for page in range(pages):
                uri = f'https://www.smwcentral.net/?p=section&s=smwsprites&u=0&g=0&n={page + 1}' \
                      f'&o=date&d=desc&f%5Btool%5D%5B%5D=142&f%5Btype%5D%5B%5D={spid}'
                with sess.get(uri) as res:
                    soup = BeautifulSoup(res.text, 'html.parser')
                links = ['https:' + link['href'] for link in soup.find_all('a', href=re.compile('dl.smwcentral.net'))]
                print(name, links)
                for link in links:
                    submission_id = link.split('/')[-2]
                    sublink = 'https://www.smwcentral.net/?p=section&a=details&id=' + submission_id
                    spritename = link.split('/')[-1].rstrip('.zip')
                    nameids[sublink] = [int(submission_id), parse.unquote(spritename)]
                    with sess.get(link) as res:
                        if res.status_code != 200:
                            del nameids[sublink]
                            with open(name + '/' + submission_id + '_error.html', 'wb') as p:
                                p.write(res.content)
                        else:
                            with open(name + '/' + submission_id + '.zip', 'wb') as p:
                                p.write(res.content)
            with open(name + '/' + 'names.json', 'w') as f:
                f.write(json.dumps(nameids, indent=4))


def create_list_files():
    for name, info in list_types.items():
        typename, start_id = info
        zipfiles = glob.glob(name + '/*.zip')
        folders = [zname.rstrip('.zip') for zname in zipfiles]
        for zname in zipfiles:
            with ZipFile(zname) as z:
                try:
                    z.extractall(zname.rstrip('.zip'))
                except Exception as e:
                    print(f'Extracting failed for {zname} in {name} because {e}')
        for folder in folders:
            if name in ['standard', 'shooter', 'generator']:
                sprites = glob.glob(folder + '/**/*.cfg', recursive=True) + \
                          glob.glob(folder + '/**/*.json', recursive=True)
            else:
                sprites = glob.glob(folder + '/**/*.asm', recursive=True)
            spid = folder.split('/')[-1]
            with open(f'{folder}/list{spid}.txt', 'w') as f:
                f.write(typename + '\n')
                f.write('\n'.join(f"{index + start_id:02X} {os.path.relpath(sprite, folder)}"
                                  for index, sprite in enumerate(sprites) if sprite.lower().find('giepy') == -1))


def ignore_giepy_dir(_, names):
    return [name for name in names if name.lower().find('giepy') != -1]


def get_routines(errors):
    found = []
    for error in re.findall("Macro '(.+)' wasn't found/. /[.+]", errors):
        if error not in found:
            found.append(error)
    return [err + '.asm' for err in found]


def exec_pixi(*, pixi_executable, current_rom, listname):
    proc = subprocess.Popen([pixi_executable, '-w', '-l', listname, current_rom],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, _) = proc.communicate()
    retval = proc.returncode
    good = True
    if retval != 0:
        stdout = stdout.decode('utf-8')
        routines = get_routines(stdout)
        all_files = glob.glob('sprites/**/*.asm', recursive=True)
        for routine in routines:
            for file in all_files:
                if os.path.basename(file) == routine:
                    copyfile(file, 'routines/' + routine)
        proc = subprocess.Popen([pixi_executable, '-l', listname, current_rom],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (stdout, _) = proc.communicate()
        retval = proc.returncode
        if retval != 0:
            good = False
    return good, stdout


def test_normal_sprites():
    differences = {}
    which_to_exec = {
        'result_current.json': ['./pixi_current', 'work_current.smc'],
        'result_latest.json': ['./pixi_latest', 'work_latest.smc']
    }
    errors = {
        'result_current.json': {},
        'result_latest.json':{}        
    }
    successes = {
        'result_current.json': {},
        'result_latest.json':{}        
    }
    base = 'standard'
    folders = [folder.rstrip('/') for folder in glob.glob(base + '/*/')]
    copyfile('pixi/sprites/_header.asm', '_header.asm')
    copytree('pixi/routines', 'routines')
    for i, folder in enumerate(folders):
        listname = 'list' + folder.split('/')[-1] + '.txt'
        copyfile(folder + '/' + listname, 'pixi/' + listname)
        rmtree('pixi/sprites/')
        rmtree('pixi/routines/')
        copytree('routines', 'pixi/routines')
        copytree(folder, 'pixi/sprites/', ignore=ignore_giepy_dir)
        for rdir in glob.glob('pixi/sprites/*/'):
            lrdir = rdir.lower()
            if 'routines' in lrdir:
                for file in glob.glob(rdir + '*'):
                    copyfile(file, 'pixi/routines/' + os.path.basename(file))
        copyfile('_header.asm', 'pixi/sprites/_header.asm')
        os.remove('pixi/sprites/list' + folder.split('/')[-1] + '.txt')
        copyfile('pixi/base_current.smc', 'pixi/work_current.smc')
        copyfile('pixi/base_latest.smc', 'pixi/work_latest.smc')
        wrkdir = os.getcwd()
        os.chdir('pixi')
        print(f'{i+1} out of {len(folders)}')
        sprite_folder_id = int(folder.split('/')[-1])
        for out_file, names in which_to_exec.items():
            pixi_exe, rom_name = names
            good, stdout = exec_pixi(pixi_executable=pixi_exe, current_rom=rom_name, listname=listname)
            try:
                stdout_str = stdout.decode('utf-8')
                if good:
                    successes[out_file][sprite_folder_id] = stdout_str
                else:
                    errors[out_file][sprite_folder_id] = stdout_str
            except UnicodeEncodeError:
                errors[out_file][sprite_folder_id] = 'BOM signature failure'
        if good:
            with open('work_current.smc', 'rb') as a, open('work_latest.smc', 'rb') as b:
                bytes_current = a.read()
                bytes_latest = b.read()
            if len(bytes_current) != len(bytes_latest):
                differences[sprite_folder_id] = 'Different rom length'
            else:
                checks = [bytes_latest[i] == bytes_current[i] for i in range(len(bytes_latest))]
                if not all(checks):
                    differences[sprite_folder_id] = 'Different bytes'
                else:
                    differences[sprite_folder_id] = 'No differences, all good'
        os.chdir(wrkdir)
        os.remove('pixi/' + listname)
    rmtree('routines')
    os.remove('_header.asm')
    return successes, errors, differences

try:
    download()
    create_list_files()
    success, error, diff = test_normal_sprites()
    for filename in ['result_current.json', 'result_latest.json']:
        with open(filename, 'w') as f:
            f.write(json.dumps({'success': success[filename], 'error': error[filename]}, indent=4))
    with open('differences.json', 'w') as f:
        f.write(json.dumps(diff, indent=4))
except Exception as e:
    with open('error_downloader.txt', 'w') as f:
        traceback.print_exception(type(e), e, e.__traceback__, file=f)
