import contextlib
import ctypes
import logging
import os
import sys
from PIL import Image
import enum
import libretro
import libretro.api.input.joypad
from libretro import Session, Rotation
import asar

if os.name == 'nt':
    _libc = ctypes.cdll.msvcrt
else:
    try:
        _libc = ctypes.CDLL(None)
    except OSError:
        import ctypes.util
        _libc = ctypes.CDLL(ctypes.util.find_library('c'))


@contextlib.contextmanager
def _suppress_c_stdout():
    sys.stdout.flush()
    saved_fd   = os.dup(1)
    devnull_fd = os.open(os.devnull, os.O_WRONLY)
    try:
        os.dup2(devnull_fd, 1)
        yield
    finally:
        _libc.fflush(None)
        os.dup2(saved_fd, 1)
        os.close(saved_fd)
        os.close(devnull_fd)

if sys.platform == 'win32':
    SNES9X_CORE = os.path.join(os.path.dirname(__file__), 'snes9x_libretro.dll')
    ASAR_DLL = os.path.join(os.path.dirname(__file__), 'pixi', 'asar.dll')
elif sys.platform == 'darwin':
    SNES9X_CORE = os.path.join(os.path.dirname(__file__), 'snes9x_libretro.dylib')
    ASAR_DLL = os.path.join(os.path.dirname(__file__), 'pixi', 'libasar.dylib')
elif sys.platform == 'linux':
    SNES9X_CORE = os.path.join(os.path.dirname(__file__), 'snes9x_libretro.so')
    ASAR_DLL = os.path.join(os.path.dirname(__file__), 'pixi', 'libasar.so')
else:
    raise NotImplementedError(f'Unsupported platform: {sys.platform}')


WRAM_GAME_MODE       = 0x0100
WRAM_LEVEL_NUM_LO    = 0x010B
WRAM_LEVEL_NUM_HI    = 0x010C
WRAM_GAME_FRAME      = 0x0014

WRAM_MARIO_X_LO      = 0x00D1
WRAM_MARIO_X_HI      = 0x00D2
WRAM_MARIO_Y_LO      = 0x00D3
WRAM_MARIO_Y_HI      = 0x00D4
WRAM_PLAYER_STATE    = 0x0071

WRAM_SPR_STATUS      = 0x14C8
WRAM_SPR_X_LO        = 0x00E4
WRAM_SPR_X_HI        = 0x14E0
WRAM_SPR_Y_LO        = 0x00D8
WRAM_SPR_Y_HI        = 0x14D4

WRAM_PIXI_EXTRA_BITS = 0x1AB10  # $7FAB10 - bit 3 marks a custom sprite
WRAM_PIXI_SPRITE_NUM = 0x1AB9E  # $7FAB9E - custom sprite number per slot

GAME_MODE_LEVEL_LOAD = 0x11
GAME_MODE_IN_LEVEL   = 0x14
PIXI_CUSTOM_BIT      = 0x08
PLAYER_DEAD          = 0x09
LEVEL_NUM_TEST       = 0x105

MAX_EMULATOR_FRAMES  = 3000
SPR_COUNT            = 12
FREEZE_THRESHOLD     = 300
SUCCESS_RUN_FRAMES   = 40
SPRITE_SETTLE_FRAMES = 10

DEFAULT_X_BLOCK = 8
DEFAULT_Y_BLOCK = 3
DEFAULT_Y_HIGH  = 1
DEFAULT_SCREEN  = 0

_DEBUG_SCREENSHOTS = os.environ.get('PIXITEST_DEBUG_SCREENSHOTS', None) is not None

if not asar.init(ASAR_DLL):
    raise RuntimeError("Failed to initialize ASAR.")


def _patch_level_sprite_data(rom_path, level_num, sprite_num,
                              extra_bit=False,
                              x_block=DEFAULT_X_BLOCK,
                              y_block=DEFAULT_Y_BLOCK,
                              y_high=DEFAULT_Y_HIGH,
                              screen=DEFAULT_SCREEN,
                              extra_byte_count=0,
                              extra_prop_bytes=None):
    log = logging.getLogger(__name__)

    with open(rom_path, 'rb') as f:
        rom = bytearray(f.read())

    hdr = 0x200 if (len(rom) % 0x8000) == 0x200 else 0

    # byte0: YYYYEEsy   (EE: bit3=custom, bit2=extra_bit; s=0; y=Y high bit)
    ee = 0b10 | (1 if extra_bit else 0)
    byte0 = (y_block << 4) | (ee << 2) | (y_high & 1)
    # byte1: XXXXssss
    byte1 = (x_block << 4) | (screen & 0x0F)
    # byte2: sprite number (pixi list slot)
    byte2 = sprite_num & 0xFF

    entry_bytes = [byte0, byte1, byte2]

    if extra_byte_count > 0:
        props = list(extra_prop_bytes or [])
        props += [0] * (extra_byte_count - len(props))
        entry_bytes += props[:extra_byte_count]

    entry_db = ', '.join(f'${b:02X}' for b in entry_bytes)

    patch_src = f"""
lorom
org ${0x05EC00 + level_num * 2:06X}
    dw sprdata
org ${0x0EF100 + level_num:06X}
    db sprdata>>16
freedata cleaned
sprdata:
    ; reuse the existing level header byte
    db read1(read2(${0x05EC00 + level_num * 2:06X})|(read1(${0x0EF100 + level_num:06X})<<16))
    db {entry_db}
    db $FF
"""

    patch_name = "sprdata.asm"

    success, patched_rom = asar.patch(
        patch_name,
        bytes(rom[hdr:]),
        warning_overrides={"relative_path_used": False},
        memory_files={patch_name: patch_src.encode("utf-8")},
    )

    if not success:
        for err in asar.geterrors():
            log.error(f'  asar: {err.fullerrdata.decode()}')
        log.error('Failed to apply sprite data patch via asar.')
        return False

    for warn in asar.getwarnings():
        log.warning(f'  asar: {warn.fullerrdata.decode()}')

    out = bytearray(rom[:hdr]) + bytearray(patched_rom)

    log.info(f'  Patched level {level_num:03X} sprite data via asar: '
             f'entry=[{" ".join(f"{b:02X}" for b in entry_bytes)}] '
             f'(screen={screen}, pos=({x_block*16},{y_high*256 + y_block*16}))')

    with open(rom_path, 'wb') as f:
        f.write(out)

    return True


class SpriteFoundPriority(enum.IntEnum):
    PERFECT_MATCH = 0
    LOST_CUSTOM_BIT = 1
    LOST_NUMBER = 2
    LOST_BOTH = 3

def _find_sprite_slot(wram, sprite_num) -> int | None:
    matches: list[tuple[int, SpriteFoundPriority]] = []
    for i in range(SPR_COUNT):
        spr_status = wram[WRAM_SPR_STATUS + i]
        spr_num = wram[WRAM_PIXI_SPRITE_NUM + i]
        spr_custom_bit = wram[WRAM_PIXI_EXTRA_BITS + i] & PIXI_CUSTOM_BIT
        if spr_status < 8:
            continue
        if spr_num == sprite_num and spr_custom_bit:
            return i
        elif spr_num == sprite_num:
            matches.append((i, SpriteFoundPriority.LOST_CUSTOM_BIT))
        elif spr_custom_bit:
            matches.append((i, SpriteFoundPriority.LOST_NUMBER))
        else:
            matches.append((i, SpriteFoundPriority.LOST_BOTH))

    if matches:
        i, _ = min(matches, key=lambda x: x[1])
        return i
    return None


def _log_freeze_diagnostic(log, wram, sprite_num, slot, freeze_start_lf):
    game_mode   = wram[WRAM_GAME_MODE]
    player_st   = wram[WRAM_PLAYER_STATE]
    spr_x       = wram[WRAM_SPR_X_LO + slot] | (wram[WRAM_SPR_X_HI + slot] << 8)
    spr_y       = wram[WRAM_SPR_Y_LO + slot] | (wram[WRAM_SPR_Y_HI + slot] << 8)
    spr_status  = wram[WRAM_SPR_STATUS + slot]
    extra_bits  = wram[WRAM_PIXI_EXTRA_BITS + slot]
    spr_num_ram = wram[WRAM_PIXI_SPRITE_NUM + slot]
    all_statuses = ' '.join(f'{wram[WRAM_SPR_STATUS + i]:02X}' for i in range(SPR_COUNT))

    log.warning(f'  --- diagnostic (level frame {freeze_start_lf}) ---')
    log.warning(f'  $0100 game mode      : ${game_mode:02X}')
    log.warning(f'  $0071 player state   : ${player_st:02X}')
    log.warning(f'  $14C8 spr statuses   : {all_statuses}  (slot {slot} = ${spr_status:02X})')
    log.warning(f'  slot {slot} position    : ({spr_x}, {spr_y})')
    log.warning(f'  slot {slot} extra bits  : ${extra_bits:02X}'
                + ('' if extra_bits & PIXI_CUSTOM_BIT else '  ← custom bit cleared!'))
    log.warning(f'  slot {slot} pixi num   : ${spr_num_ram:02X}'
                + (f'  ← changed from ${sprite_num:02X}!' if spr_num_ram != sprite_num else ''))

def save_screenshot_to_png(session: Session, file_path: str) -> None:
    if not _DEBUG_SCREENSHOTS:
        return
    screenshot = session.video.screenshot()
    img = Image.frombuffer(
        'RGB',
        (screenshot.width, screenshot.height),
        screenshot.data,
        'raw',
        'RGBX',
        0,
        1
    )
    if screenshot.rotation == Rotation.NINETY:
        img = img.transpose(Image.Transpose.ROTATE_90)
    elif screenshot.rotation == Rotation.ONE_EIGHTY:
        img = img.transpose(Image.Transpose.ROTATE_180)
    elif screenshot.rotation == Rotation.TWO_SEVENTY:
        img = img.transpose(Image.Transpose.ROTATE_270)
    img = img.convert("RGB")
    img.save(file_path, format="PNG")

class GameState(enum.IntEnum):
    NONE = -1
    LOADING_LEVEL = 0
    IN_LEVEL = 1
    RUNNING = 2

def run_emulator_test(rom_path: str, sprite_num: int,
                      smwc_id: int,
                      extra_bit: bool = False,
                      extra_byte_count: int = 0,
                      extra_prop_bytes: list | None = None) -> bool:
    log = logging.getLogger(__name__)

    if not _patch_level_sprite_data(
        rom_path, LEVEL_NUM_TEST, sprite_num,
        extra_bit=extra_bit,
        extra_byte_count=extra_byte_count,
        extra_prop_bytes=extra_prop_bytes,
    ):
        return False

    in_level = GameState.NONE
    def input_gen() -> libretro.drivers.input.InputStateIterator:
        while True:
            yield [libretro.api.input.joypad.JoypadState()]

    session = libretro.Session(
        core=SNES9X_CORE,
        content=libretro.StandardContentDriver(),
        game=rom_path,
        input=libretro.IterableInputDriver(input_gen),
        video=libretro.MultiVideoDriver(),
        log=None,
        audio=libretro.ArrayAudioDriver(),
    )

    prev_game_frame = -1
    frozen_frames   = 0
    freeze_start_lf = None
    level_frames    = 0
    sprite_slot     = None
    loading_frames  = 0
    with _suppress_c_stdout(), session as session:
        for emu_frame in range(MAX_EMULATOR_FRAMES):
            session.run()

            wram = session.core.get_memory(2)
            if wram is None:
                continue

            game_mode = wram[WRAM_GAME_MODE]
            # enable sprite buoyancy every frame; doing it once on "level found" is not enough
            wram[0x190E] = 0b1100_0000
            if in_level == GameState.NONE:
                level_num = wram[WRAM_LEVEL_NUM_LO] | (wram[WRAM_LEVEL_NUM_HI] << 8)
                if game_mode >= GAME_MODE_LEVEL_LOAD and game_mode < GAME_MODE_IN_LEVEL and level_num == LEVEL_NUM_TEST:
                    in_level = GameState.LOADING_LEVEL
                    loading_frames = 0
                else:
                    continue
            elif in_level == GameState.LOADING_LEVEL:
                loading_frames += 1
                level_num = wram[WRAM_LEVEL_NUM_LO] | (wram[WRAM_LEVEL_NUM_HI] << 8)
                if game_mode == GAME_MODE_IN_LEVEL and level_num == LEVEL_NUM_TEST:
                    in_level = GameState.IN_LEVEL
            elif in_level == GameState.IN_LEVEL:
                level_num = wram[WRAM_LEVEL_NUM_LO] | (wram[WRAM_LEVEL_NUM_HI] << 8)
                mario_x = wram[WRAM_MARIO_X_LO] | (wram[WRAM_MARIO_X_HI] << 8)
                mario_y = wram[WRAM_MARIO_Y_LO] | (wram[WRAM_MARIO_Y_HI] << 8)
                cam_x = wram[0x1A] | (wram[0x1B] << 8)
                cam_y = wram[0x1C] | (wram[0x1D] << 8)
                log.info(f'  Reached level {level_num:03X} at emulator frame {emu_frame} after {loading_frames} loading frames')
                log.info(f'  Mario=({mario_x},{mario_y}) camera=({cam_x},{cam_y})')
                in_level = GameState.RUNNING
            else:
                level_frames += 1

            if sprite_slot is None and in_level != GameState.NONE:
                sprite_slot = _find_sprite_slot(wram, sprite_num)
                if sprite_slot is not None:
                    s = sprite_slot
                    spr_x = wram[WRAM_SPR_X_LO + s] | (wram[WRAM_SPR_X_HI + s] << 8)
                    spr_y = wram[WRAM_SPR_Y_LO + s] | (wram[WRAM_SPR_Y_HI + s] << 8)
                    log.info(f'  Sprite ${sprite_num:02X} found in slot {sprite_slot} '
                              f'at ({spr_x}, {spr_y}), '
                              f'status=${wram[WRAM_SPR_STATUS + s]:02X} (game mode ${game_mode:02X})')
                elif level_frames == SPRITE_SETTLE_FRAMES:
                    all_st = ' '.join(f'{wram[WRAM_SPR_STATUS + i]:02X}' for i in range(SPR_COUNT))
                    log.warning(f'  Sprite ${sprite_num:02X} not found in any slot after '
                                f'{SPRITE_SETTLE_FRAMES} frames. Statuses: {all_st}')
                    save_screenshot_to_png(session, f'FAIL_{smwc_id}_{sprite_num:02X}.png')
                    return False

            cur_game_frame = wram[WRAM_GAME_FRAME]
            if cur_game_frame == prev_game_frame:
                if frozen_frames == 0:
                    freeze_start_lf = level_frames
                frozen_frames += 1
                if frozen_frames > FREEZE_THRESHOLD:
                    if wram[WRAM_PLAYER_STATE] == PLAYER_DEAD:
                        log.warning(f'  Mario died after {level_frames} level frames - no crash.')
                        save_screenshot_to_png(session, f'PASS_{smwc_id}_{sprite_num:02X}.png')
                        return True
                    slot = sprite_slot if sprite_slot is not None else 0
                    _log_freeze_diagnostic(log, wram, sprite_num, slot, freeze_start_lf)
                    save_screenshot_to_png(session, f'FAIL_{smwc_id}_{sprite_num:02X}.png')
                    return False
            else:
                frozen_frames   = 0
                freeze_start_lf = None
            prev_game_frame = cur_game_frame

            if level_frames > SUCCESS_RUN_FRAMES:
                save_screenshot_to_png(session, f'PASS_{smwc_id}_{sprite_num:02X}.png')
                log.info(f'  Sprite ran for {SUCCESS_RUN_FRAMES} level frames without crashing.')
                return True
        if in_level == GameState.NONE:
            save_screenshot_to_png(session, f'FAIL_{smwc_id}_{sprite_num:02X}.png')
            log.warning(f'  Never reached the test level within {MAX_EMULATOR_FRAMES} emulator frames.')
    return in_level == GameState.RUNNING
