import os
import json
import glob
import zipfile
from shutil import copyfile, rmtree, copytree
import subprocess
import re
import traceback
import sys
import argparse
from downloader import download
from emulator import run_emulator_test
if sys.platform == 'win32':
    LIBPIXI_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pixi', 'pixi_api.dll')
elif sys.platform == 'darwin':
    LIBPIXI_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pixi', 'libpixi_api.dylib')
elif sys.platform == 'linux':
    LIBPIXI_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pixi', 'libpixi_api.so')
else:
    raise NotImplementedError(f'Unsupported platform: {sys.platform}')
os.environ["PIXI_API_DLL_PATH"] = LIBPIXI_PATH
from pixi.pixi_api import ParsedListResult, ListType

_EMU_TESTING_ROM = 'testing.smc'
_DEBUG_SCREENSHOTS = os.environ.get('PIXITEST_DEBUG_SCREENSHOTS', None) is not None

list_types = {
    'standard': ('SPRITE:', 0),
    'shooter': ('SPRITE:', 0xC0),
    'generator': ('SPRITE:', 0xD0),
    'cluster': ('CLUSTER:', 0),
    'extended': ('EXTENDED:', 0)
}

def executable_name(name: str) -> str:
    if sys.platform == 'win32':
        return name + '.exe'
    elif sys.platform == 'linux':
        return name
    elif sys.platform == 'darwin':
        return name

def create_list_files(cached = False):
    for name, info in list_types.items():
        typename, start_id = info
        zipfiles = glob.glob(name + '/*.zip')
        folders = [zname.rstrip('.zip') for zname in zipfiles]
        # if not using cached, extract zips, do nothing otherwise.
        if not cached:
            for zname in zipfiles:
                with zipfile.ZipFile(zname) as z:
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
            spid = folder.split(os.sep)[-1]
            with open(f'{folder}/list{spid}.txt', 'w') as f:
                f.write(typename + '\n')
                f.write('\n'.join(f"{index + start_id:02X} {os.path.relpath(sprite, folder)}"
                                  for index, sprite in enumerate(sprites) if sprite.lower().find('giepy') == -1))


def ignore_giepy_dir(_, names):
    return [name for name in names if name.lower().find('giepy') != -1]


def get_routines(errors):
    found = []
    for error in re.findall(r"Macro '(.+)' wasn't found\.", errors):
        if error not in found:
            found.append(error)
    return [err + '.asm' for err in found]

def get_remove_routines(errors):
    found = []
    for error in re.findall(r"Macro '(.+)' redefined\.", errors):
        if error not in found:
            found.append(error)
    return [err + '.asm' for err in found]

def get_not_found_files(errors):
    found = {}
    split_errors = errors.split('\n')
    for single_error in split_errors:
        if m := re.findall(r"File '(.+)' wasn't found.", single_error):
            if len(m) > 0:
                if m[0] not in found:
                    found[m[0]] = [single_error.split(':')[0]]
                else:
                    found[m[0]].append(single_error.split(':')[0])
    return found


def exec_pixi(*, pixi_executable, current_rom, listname):
    proc = subprocess.Popen([pixi_executable, '-l', listname, current_rom],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
    (stdout, _) = proc.communicate(input=b'yes\n')
    retval = proc.returncode
    good = True
    files_in_sprite_folder = {os.path.basename(p): p for p in glob.glob('sprites/**/*.*', recursive=True)}
    with open(listname, 'r') as t:
        listlen = len(t.readlines())
    tries = 0
    while retval != 0:
        good = True
        tries += 1
        stdout = stdout.decode('utf-8')
        routines = get_routines(stdout)
        routines_to_remove = get_remove_routines(stdout)
        not_found_files = get_not_found_files(stdout)
        all_files = glob.glob('sprites/**/*.asm', recursive=True)
        existing_routines = glob.glob('routines/*.asm')
        for file_not_found, sprites_called_from in not_found_files.items():
            filename = os.path.basename(file_not_found)
            fullpath = files_in_sprite_folder.get(filename)
            if fullpath is None:
                continue
            for sprite_called_from in sprites_called_from:
                sprite_folder = os.path.abspath(os.path.dirname(sprite_called_from))
                required_location = os.path.join(sprite_folder, file_not_found if not os.path.isabs(file_not_found) else os.path.relpath(file_not_found, sprite_folder))
                copyfile(fullpath, required_location)
        for routine in routines:
            for file in all_files:
                if os.path.basename(file) == routine:
                    copyfile(file, 'routines/' + routine)
        for routine in routines_to_remove:
            for existing in existing_routines:
                if os.path.basename(existing) == routine:
                    os.remove(existing)
        proc = subprocess.Popen([pixi_executable, '--script-mode', '-l', listname, current_rom],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        (stdout, _) = proc.communicate(input=b'yes\n')
        retval = proc.returncode
        if retval != 0:
            good = False
        if tries > listlen:
            break
    return good, stdout


def _run_emu_tests(pixi_exe, listname, smwc_id: int):
    if not os.path.isfile(_EMU_TESTING_ROM):
        print('  [emu] testing.smc not found, skipping runtime tests.')
        return {}

    copyfile(_EMU_TESTING_ROM, 'emu_test.smc')
    proc = subprocess.Popen(
        [pixi_exe, '--script-mode', '-l', listname, 'emu_test.smc'],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
    proc.communicate(input=b'yes\n')
    if proc.returncode != 0:
        print('  [emu] Insertion into testing ROM failed, skipping runtime tests.')
        os.remove('emu_test.smc')
        return {}

    list_result = ParsedListResult(os.path.abspath(listname))
    if not list_result.success():
        print('  [emu] Failed to parse sprite list, skipping runtime tests.')
        return {}

    emu_rom = os.path.abspath('emu_test.smc')
    results = {}
    for spr in list_result.sprite_array(ListType.Normal):
        sprite_num  = spr.number()
        sprite_name = spr.cfg_file()
        colls       = spr.collections()
        extra_bit        = bool(colls[0].extra_bit()) if colls else False
        extra_byte_count = spr.extra_byte_count() if extra_bit else spr.byte_count()
        extra_prop_bytes = list(colls[0].prop()) if colls else []
        if smwc_id == 13807: # Special case for the BooRing, this is horrible...
            extra_prop_bytes = [0x0A, 0x28, 0x50, 0x10]
        print(f'  [emu] sprite ${sprite_num:02X} ({sprite_name})... ', end='', flush=True)
        ok = run_emulator_test(emu_rom, sprite_num,
                                smwc_id=smwc_id,
                                extra_bit=extra_bit,
                                extra_byte_count=extra_byte_count,
                                extra_prop_bytes=extra_prop_bytes)
        results[sprite_num] = ok
        print('PASS' if ok else 'FAIL')

    os.remove('emu_test.smc')
    return results


def test_normal_sprites(sprites = None, run_emu = False) -> tuple[dict[int, str], dict[int, str], dict[int, dict[str, bool]]]:
    execlist = [executable_name('./pixi'), 'work.smc']
    successes = {}
    errors = {}
    emu_results = {}
    base = 'standard'
    folders = [folder.rstrip(os.sep) for folder in glob.glob(base + '/*/')]
    if sprites is not None:
        folders = [folder for folder in folders if int(folder.split(os.sep)[-1]) in sprites]
    copyfile('pixi/sprites/_header.asm', '_header.asm')
    copytree('pixi/routines', 'routines', dirs_exist_ok=True)
    if _DEBUG_SCREENSHOTS:
        os.makedirs('screenshots', exist_ok=True)
    for i, folder in enumerate(folders):
        sprite_folder_id = folder.split(os.sep)[-1]
        listname = 'list' + sprite_folder_id + '.txt'
        copyfile(folder + '/' + listname, 'pixi/' + listname)
        rmtree('pixi/sprites/')
        rmtree('pixi/routines/')
        copytree('routines', 'pixi/routines', dirs_exist_ok=True)
        copytree(folder, 'pixi/sprites/', ignore=ignore_giepy_dir, dirs_exist_ok=True)
        for rdir in glob.glob('pixi/sprites/*/'):
            lrdir = rdir.lower()
            if 'routines' in lrdir:
                for file in glob.glob(rdir + '*'):
                    if os.path.isfile(file):
                        copyfile(file, 'pixi/routines/' + os.path.basename(file))
                    elif os.path.isdir(file):
                        copytree(file, 'pixi/routines/' + os.path.basename(file), dirs_exist_ok=True)
        copyfile('_header.asm', 'pixi/sprites/_header.asm')
        os.remove('pixi/sprites/list' + sprite_folder_id + '.txt')
        copyfile('pixi/base.smc', 'pixi/work.smc')
        wrkdir = os.getcwd()
        os.chdir('pixi')
        print(f'Testing sprite {i+1} (id: {sprite_folder_id}) out of {len(folders)}')
        pixi_exe, rom_name = execlist
        good, stdout = exec_pixi(pixi_executable=pixi_exe, current_rom=rom_name, listname=listname)
        sprite_folder_id = int(sprite_folder_id)
        try:
            stdout_str = stdout.decode('utf-8')
            if good:
                successes[sprite_folder_id] = stdout_str
                if run_emu:
                    emu_result = _run_emu_tests(pixi_exe, listname, smwc_id=sprite_folder_id)
                    emu_results[sprite_folder_id] = emu_result
                    if _DEBUG_SCREENSHOTS:
                        screenshots = glob.glob('*.png')
                        for ss in screenshots:
                            copyfile(ss, os.path.join(wrkdir, 'screenshots', ss))
            else:
                errors[sprite_folder_id] = stdout_str
        except UnicodeEncodeError:
            errors[sprite_folder_id] = 'BOM signature failure'
        os.chdir(wrkdir)
        os.remove('pixi/' + listname)
    rmtree('routines')
    os.remove('_header.asm')
    return successes, errors, emu_results

def read_expected():
    expected_results = {'PASS': [], 'FAIL': []}
    with open('EXPECTED.lst', 'r') as f:
        expected = f.readlines()
    for e in expected:
        num, res = e.split(' ')
        expected_results[res.strip()].append(int(num))
    return expected_results

argparser = argparse.ArgumentParser('runner.py', description='Test sprites with pixi')
argparser.add_argument('-c', '--cached', action='store_true', help='Use cached sprites', required=False, default=False)
argparser.add_argument('-s', '--sprites', nargs='*', help='Sprites to test (ids)', required=False, default=None)
argparser.add_argument('-e', '--emu', action='store_true', default=False,
                       help='Also run in-game stability tests via snes9x-libretro (requires emu/ setup)')
args = argparser.parse_args()


try:
    if not args.cached:
        args.cached = download()
    else:
        print("Using cached sprites")
    create_list_files(cached=args.cached)
    sprites_to_test = [int(spr) for spr in args.sprites] if args.sprites is not None else None
    success, error, emu_results = test_normal_sprites(sprites=sprites_to_test, run_emu=args.emu)
    diffs = ''
    expected_res = read_expected()
    for s in success.keys():
        if s not in expected_res['PASS'] and s not in expected_res['FAIL']:
            print(f"Sprite {s} wasn't expected to be tested, but passed")
            # sprite wasn't expected to be tested, but passed, it was most likely recently moderated and accepted
            diffs += f'+ {s} PASS\n'
    for s in error.keys():
        if s not in expected_res['PASS'] and s not in expected_res['FAIL']:
            print(f"Sprite {s} wasn't expected to be tested, but failed")
            # sprite wasn't expected to be tested, but passed, it was most likely recently moderated and accepted
            diffs += f'+ {s} FAIL\n'

    if sprites_to_test is None:
        for s in expected_res['PASS']:
            if success.get(s) is None and error.get(s) is not None:
                print(f"Sprite {s} should have passed but failed")
            elif success.get(s) is None and error.get(s) is None:
                # sprite wasn't tested, most likely it was either removed from the section or overwritten by an update
                print(f"Sprite {s} wasn't tested, but should have passed")
                diffs += f'- {s} PASS\n'
        for s in expected_res['FAIL']:
            if error.get(s) is None and success.get(s) is not None:
                print(f"Sprite {s} should have failed but passed")
            elif error.get(s) is None and success.get(s) is None:
                # sprite wasn't tested, most likely it was either removed from the section or overwritten by an update
                print(f"Sprite {s} wasn't tested, but should have failed")
                diffs += f'- {s} FAIL\n'
    else:
        for s in sprites_to_test:
            if s in expected_res['PASS'] and success.get(s) is None and error.get(s) is not None:
                print(f"Sprite {s} should have passed but failed")
            elif s in expected_res['FAIL'] and success.get(s) is not None and error.get(s) is None:
                print(f"Sprite {s} should have failed but passed")
    print("Finished testing all sprites")
    filename = 'result.json'
    result = {'success': success, 'error': error, 'emu_failures': []}
    if emu_results:
        result['emu_failures'] = [{sprite_id: [test for test, ok in tests.items() if not ok]} for sprite_id, tests in emu_results.items() if any(not ok for ok in tests.values())]
    with open(filename, 'w') as f:
        f.write(json.dumps(result, indent=4))
    print("Written results to file")
    if diffs != '':
        with open('diffs.txt', 'w') as f:
            f.write(diffs)
        print(f"Found differences between expected and tested sprites, written to diffs.txt, run the apply_diffs.py script to apply them to EXPECTED.lst")
except Exception as e:
    with open('error_downloader.txt', 'w') as f:
        traceback.print_exception(type(e), e, e.__traceback__, file=f)
    print("Exception happened " + str(e))
print("All done!")
