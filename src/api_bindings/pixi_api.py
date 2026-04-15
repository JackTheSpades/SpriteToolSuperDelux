from __future__ import annotations
from typing import Callable, TYPE_CHECKING, Optional
from ctypes import CDLL, POINTER, c_char_p, c_int, c_void_p, c_ubyte, byref, c_bool, string_at, Array, _Pointer, _CArgObject
import sys
from enum import IntEnum

__all__ = ["run", "api_version", "check_api_version", "Sprite", "ParsedListResult", "SpriteTable", "Tile", "StatusPointers", "Map8x8", "Map16", "Display", "Collection"]
_pixi: _PixiDll = None # type: ignore

if TYPE_CHECKING:
    type IntPointer = _Pointer[c_int] |_CArgObject
    type BytePointer = _Pointer[c_ubyte]
    type VoidPointer = _Pointer[c_void_p]
    type CharPointer = _Pointer[c_char_p]
else:
    IntPointer = POINTER(c_int)
    VoidPointer = POINTER(c_void_p)
    BytePointer = POINTER(c_ubyte)
    CharPointer = POINTER(c_char_p)

class ListType(IntEnum):
    Normal = 0
    Cluster = 1
    Extended = 2
    MinorExtended = 3
    Bounce = 4
    Smoke = 5
    SpinningCoin = 6
    Score = 7

class _PixiDll:
    run: Callable[[c_int, Array[c_char_p], c_bool], c_int]
    api_version: Callable[[], c_int]
    check_api_version: Callable[[c_int, c_int, c_int], c_int]

    parse_list_file: Callable[[c_char_p, c_bool], c_void_p]
    list_result_success: Callable[[c_void_p], c_int]
    list_result_sprite_array: Callable[[c_void_p, c_int, IntPointer], VoidPointer]
    list_result_free: Callable[[c_void_p], None]

    parse_json_sprite: Callable[[c_char_p], c_void_p]
    parse_cfg_sprite: Callable[[c_char_p], c_void_p]
    sprite_free: Callable[[c_void_p], None]
    free_map16_buffer: Callable[[c_void_p], None]
    free_map16_array: Callable[[VoidPointer], None]
    free_display_array: Callable[[VoidPointer], None]
    free_collection_array: Callable[[VoidPointer], None]
    free_tile_array: Callable[[VoidPointer], None]
    free_string: Callable[[c_void_p], None]
    free_byte_array: Callable[[BytePointer], None]

    sprite_line: Callable[[c_void_p], c_int]
    sprite_number: Callable[[c_void_p], c_int]
    sprite_level: Callable[[c_void_p], c_int]
    sprites_sprite_table: Callable[[c_void_p], c_void_p]
    sprite_status_pointers: Callable[[c_void_p], c_void_p]
    extended_cape_ptr: Callable[[c_void_p], c_int]
    sprite_byte_count: Callable[[c_void_p], c_int]
    sprite_extra_byte_count: Callable[[c_void_p], c_int]
    sprite_directory: Callable[[c_void_p, IntPointer], bytes]
    sprite_asm_file: Callable[[c_void_p, IntPointer], bytes]
    sprite_cfg_file: Callable[[c_void_p, IntPointer], bytes]
    sprite_map_data: Callable[[c_void_p, IntPointer], VoidPointer]
    sprite_displays: Callable[[c_void_p, IntPointer], VoidPointer]
    sprite_collections: Callable[[c_void_p, IntPointer], VoidPointer]
    sprite_type: Callable[[c_void_p], c_int]

    tile_x_offset: Callable[[c_void_p], c_int]
    tile_y_offset: Callable[[c_void_p], c_int]
    tile_tile_number: Callable[[c_void_p], c_int]
    tile_text: Callable[[c_void_p, IntPointer], bytes]

    display_description: Callable[[c_void_p, IntPointer], bytes]
    display_tiles: Callable[[c_void_p, IntPointer], VoidPointer]
    display_extra_bit: Callable[[c_void_p], c_int]
    display_x: Callable[[c_void_p], c_int]
    display_y: Callable[[c_void_p], c_int]

    collection_name: Callable[[c_void_p, IntPointer], bytes]
    collection_extra_bit: Callable[[c_void_p], c_int]
    collection_prop: Callable[[c_void_p, IntPointer], BytePointer]

    map8x8_tile: Callable[[c_void_p], c_ubyte]
    map8x8_prop: Callable[[c_void_p], c_ubyte]

    map16_top_left: Callable[[c_void_p], c_void_p]
    map16_top_right: Callable[[c_void_p], c_void_p]
    map16_bottom_left: Callable[[c_void_p], c_void_p]
    map16_bottom_right: Callable[[c_void_p], c_void_p]

    status_pointers_carriable: Callable[[c_void_p], c_int]
    status_pointers_carried: Callable[[c_void_p], c_int]
    status_pointers_kicked: Callable[[c_void_p], c_int]
    status_pointers_mouth: Callable[[c_void_p], c_int]
    status_pointers_goal: Callable[[c_void_p], c_int]

    sprite_table_type: Callable[[c_void_p], c_ubyte]
    sprite_table_actlike: Callable[[c_void_p], c_ubyte]
    sprite_table_tweak: Callable[[c_void_p, IntPointer], BytePointer]
    sprite_table_init: Callable[[c_void_p], c_int]
    sprite_table_main: Callable[[c_void_p], c_int]
    sprite_table_extra: Callable[[c_void_p, IntPointer], BytePointer]

    last_error: Callable[[IntPointer], bytes]
    output: Callable[[IntPointer], CharPointer]

    create_map16_buffer: Callable[[c_int], c_void_p]
    generate_s16: Callable[[c_void_p, c_void_p, c_int, IntPointer, IntPointer], VoidPointer]
    generate_ssc: Callable[[c_void_p, c_int, c_int], c_void_p]
    generate_mwt: Callable[[c_void_p, c_void_p, c_int], c_void_p]
    generate_mw2: Callable[[c_void_p, c_void_p, IntPointer], BytePointer]

    def __init__(self, dllname):
        dll = CDLL(dllname)
        self.dll = dll

    def setup_func(self, name, argtypes, restype):
        func = getattr(self.dll, "pixi_" + name)
        func.argtypes = argtypes
        func.restype = restype
        setattr(self, name, func)


def __init_pixi_dll():
    global _pixi
    if _pixi:
        return
    _pixi_dll_path = os.environ.get("PIXI_API_DLL_PATH")
    if _pixi_dll_path:
        _pixi = _PixiDll(_pixi_dll_path)
    elif sys.platform == "win32":
        _pixi = _PixiDll("./pixi_api.dll")
    elif sys.platform == "darwin":
        _pixi = _PixiDll("./libpixi_api.dylib")
    else:
        _pixi = _PixiDll("./libpixi_api.so")

    _pixi.setup_func("run", [c_int, POINTER(c_char_p), c_bool], c_int)
    _pixi.setup_func("api_version", [], c_int)
    _pixi.setup_func("check_api_version", [c_int, c_int, c_int], c_int)

    _pixi.setup_func("parse_list_file", [c_char_p, c_bool], c_void_p)
    _pixi.setup_func("list_result_success", [c_void_p], c_int)
    _pixi.setup_func("list_result_sprite_array", [c_void_p, c_int, POINTER(c_int)], POINTER(c_void_p))
    _pixi.setup_func("list_result_free", [c_void_p], None)

    _pixi.setup_func("parse_json_sprite", [c_char_p], c_void_p)
    _pixi.setup_func("parse_cfg_sprite", [c_char_p], c_void_p)
    _pixi.setup_func("sprite_free", [c_void_p], None)
    _pixi.setup_func("free_map16_buffer", [c_void_p], None)
    _pixi.setup_func("free_map16_array", [c_void_p], None)
    _pixi.setup_func("free_display_array", [c_void_p], None)
    _pixi.setup_func("free_collection_array", [c_void_p], None)
    _pixi.setup_func("free_tile_array", [c_void_p], None)
    _pixi.setup_func("free_string", [c_void_p], None)
    _pixi.setup_func("free_byte_array", [c_void_p], None)

    _pixi.setup_func("sprite_line", [c_void_p], c_int)
    _pixi.setup_func("sprite_number", [c_void_p], c_int)
    _pixi.setup_func("sprite_level", [c_void_p], c_int)
    _pixi.setup_func("sprites_sprite_table", [c_void_p], c_void_p)
    _pixi.setup_func("extended_cape_ptr", [c_void_p], c_int)
    _pixi.setup_func("sprite_byte_count", [c_void_p], c_int)
    _pixi.setup_func("sprite_extra_byte_count", [c_void_p], c_int)
    _pixi.setup_func("sprite_directory", [c_void_p, POINTER(c_int)], c_char_p)
    _pixi.setup_func("sprite_asm_file", [c_void_p, POINTER(c_int)], c_char_p)
    _pixi.setup_func("sprite_cfg_file", [c_void_p, POINTER(c_int)], c_char_p)
    _pixi.setup_func("sprite_map_data", [c_void_p, POINTER(c_int)], POINTER(c_void_p))
    _pixi.setup_func("sprite_displays", [c_void_p, POINTER(c_int)], POINTER(c_void_p))
    _pixi.setup_func("sprite_collections", [c_void_p, POINTER(c_int)], POINTER(c_void_p))
    _pixi.setup_func("sprite_type", [c_void_p], c_int)

    _pixi.setup_func("tile_x_offset", [c_void_p], c_int)
    _pixi.setup_func("tile_y_offset", [c_void_p], c_int)
    _pixi.setup_func("tile_tile_number", [c_void_p], c_int)
    _pixi.setup_func("tile_text", [c_void_p, POINTER(c_int)], c_char_p)

    _pixi.setup_func("display_description", [c_void_p, POINTER(c_int)], c_char_p)
    _pixi.setup_func("display_tiles", [c_void_p, POINTER(c_int)], POINTER(c_void_p))
    _pixi.setup_func("display_extra_bit", [c_void_p], c_int)
    _pixi.setup_func("display_x", [c_void_p], c_int)
    _pixi.setup_func("display_y", [c_void_p], c_int)

    _pixi.setup_func("collection_name", [c_void_p, POINTER(c_int)], c_char_p)
    _pixi.setup_func("collection_extra_bit", [c_void_p], c_int)
    _pixi.setup_func("collection_prop", [c_void_p, POINTER(c_int)], POINTER(c_ubyte))

    _pixi.setup_func("map8x8_tile", [c_void_p], c_ubyte)
    _pixi.setup_func("map8x8_prop", [c_void_p], c_ubyte)

    _pixi.setup_func("map16_top_left", [c_void_p], c_void_p)
    _pixi.setup_func("map16_top_right", [c_void_p], c_void_p)
    _pixi.setup_func("map16_bottom_left", [c_void_p], c_void_p)
    _pixi.setup_func("map16_bottom_right", [c_void_p], c_void_p)

    _pixi.setup_func("status_pointers_carriable", [c_void_p], c_int)
    _pixi.setup_func("status_pointers_carried", [c_void_p], c_int)
    _pixi.setup_func("status_pointers_kicked", [c_void_p], c_int)
    _pixi.setup_func("status_pointers_mouth", [c_void_p], c_int)
    _pixi.setup_func("status_pointers_goal", [c_void_p], c_int)

    _pixi.setup_func("sprite_table_type", [c_void_p], c_ubyte)
    _pixi.setup_func("sprite_table_actlike", [c_void_p], c_ubyte)
    _pixi.setup_func("sprite_table_tweak", [c_void_p, POINTER(c_int)], POINTER(c_ubyte))
    _pixi.setup_func("sprite_table_init", [c_void_p], c_int)
    _pixi.setup_func("sprite_table_main", [c_void_p], c_int)
    _pixi.setup_func("sprite_table_extra", [c_void_p, POINTER(c_int)], POINTER(c_ubyte))

    _pixi.setup_func("last_error", [POINTER(c_int)], c_char_p)
    _pixi.setup_func("output", [POINTER(c_int)], POINTER(c_char_p))

    _pixi.setup_func("create_map16_buffer", [c_int], c_void_p)
    _pixi.setup_func("generate_s16", [c_void_p, c_void_p, c_int, POINTER(c_int), POINTER(c_int)], POINTER(c_void_p))
    _pixi.setup_func("generate_ssc", [c_void_p, c_int, c_int], c_void_p)
    _pixi.setup_func("generate_mwt", [c_void_p, c_void_p, c_int], c_void_p)
    _pixi.setup_func("generate_mw2", [c_void_p, c_void_p, POINTER(c_int)], POINTER(c_ubyte))

__init_pixi_dll()

def _check_cstr(cstr: bytes, expected_len: c_int):
    actual_len = len(cstr) if cstr else 0
    assert(actual_len == expected_len.value), f"Expected C string of length {expected_len.value}, got {actual_len}"


class Tile:
    data_ptr: c_void_p
    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def x_offset(self) -> int:
        return int(_pixi.tile_x_offset(self.data_ptr))
    
    def y_offset(self) -> int:
        return int(_pixi.tile_y_offset(self.data_ptr))
    
    def tile_number(self) -> int:
        return int(_pixi.tile_tile_number(self.data_ptr))
    
    def text(self) -> str:
        size = c_int()
        cstr: bytes = _pixi.tile_text(self.data_ptr, byref(size))
        _check_cstr(cstr, size)
        return str(cstr, encoding="utf-8")

class SpriteTable:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def type(self) -> int:
        return int(_pixi.sprite_table_type(self.data_ptr))
    
    def actlike(self) -> int:
        return int(_pixi.sprite_table_actlike(self.data_ptr))
    
    def tweak(self) -> bytearray:
        size = c_int()
        ptr = _pixi.sprite_table_tweak(self.data_ptr, byref(size))
        tweaks = bytearray()
        for i in range(int(size.value)):
            tweaks.append(ptr[i])
        return tweaks
    
    def init(self) -> int:
        return int(_pixi.sprite_table_init(self.data_ptr))
    
    def main(self) -> int:
        return int(_pixi.sprite_table_main(self.data_ptr))
    
    def extra(self) -> bytearray:
        size = c_int()
        ptr = _pixi.sprite_table_extra(self.data_ptr, byref(size))
        extras = bytearray()
        for i in range(int(size.value)):
            extras.append(ptr[i])
        return extras

class StatusPointers:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def carriable(self) -> int:
        return int(_pixi.status_pointers_carriable(self.data_ptr))
    
    def carried(self) -> int:
        return int(_pixi.status_pointers_carried(self.data_ptr))
    
    def kicked(self) -> int:
        return int(_pixi.status_pointers_kicked(self.data_ptr))
    
    def mouth(self) -> int:
        return int(_pixi.status_pointers_mouth(self.data_ptr))
    
    def goal(self) -> int:
        return int(_pixi.status_pointers_goal(self.data_ptr))

class Map8x8:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def tile(self) -> int:
        return int(_pixi.map8x8_tile(self.data_ptr))
    
    def prop(self) -> int:
        return int(_pixi.map8x8_prop(self.data_ptr))

class Map16:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def top_left(self) -> Map8x8:
        return Map8x8(_pixi.map16_top_left(self.data_ptr))
    
    def top_right(self) -> Map8x8:
        return Map8x8(_pixi.map16_top_right(self.data_ptr))
    
    def bottom_left(self) -> Map8x8:
        return Map8x8(_pixi.map16_bottom_left(self.data_ptr))
    
    def bottom_right(self) -> Map8x8:
        return Map8x8(_pixi.map16_bottom_right(self.data_ptr))

class Display:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def description(self) -> str:
        size = c_int()
        cstr: bytes = _pixi.display_description(self.data_ptr, byref(size))
        _check_cstr(cstr, size)
        return str(cstr, encoding="utf-8")
    
    def tiles(self) -> list[Tile]:
        size = c_int()
        ptr = _pixi.display_tiles(self.data_ptr, byref(size))
        tiles = []
        for i in range(int(size.value)):
            tiles.append(Tile(ptr[i]))
        return tiles

    def extra_bit(self) -> int:
        return int(_pixi.display_extra_bit(self.data_ptr))
    
    def x(self) -> int:
        return int(_pixi.display_x(self.data_ptr))
    
    def y(self) -> int:
        return int(_pixi.display_y(self.data_ptr))

class Collection:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def name(self) -> str:
        size = c_int()
        cstr: bytes = _pixi.collection_name(self.data_ptr, byref(size))
        _check_cstr(cstr, size)
        return str(cstr, encoding="utf-8")
    
    def extra_bit(self) -> int:
        return int(_pixi.collection_extra_bit(self.data_ptr))
    
    def prop(self) -> bytearray:
        size = c_int()
        ptr = _pixi.collection_prop(self.data_ptr, byref(size))
        props = bytearray()
        for i in range(int(size.value)):
            props.append(ptr[i])
        return props

class Sprite:
    data_ptr: c_void_p
    freed: bool
    _constructed_from_raw: bool
    map16_data: c_void_p
    map16_tile: c_int
    _s16: Optional[list[Map16]]


    def __init__(self, filename: str | None = None):
        self.freed = False
        self.map16_data = c_void_p(0)
        self._s16 = None
        self.map16_tile = c_int(0)
        self._constructed_from_raw = False
        if filename is None:
            return
        cfilename = c_char_p(filename.encode())
        if filename.endswith(".json"):
            self.data_ptr = _pixi.parse_json_sprite(cfilename)
        elif filename.endswith(".cfg"):
            self.data_ptr = _pixi.parse_cfg_sprite(cfilename)
        else:
            raise ValueError("Unknown sprite file extension")

    def __enter__(self):
        return self
    
    def __exit__(self):
        if not self.freed:
            if not self._constructed_from_raw:
                _pixi.sprite_free(self.data_ptr)
            if self.map16_data:
                _pixi.free_map16_buffer(self.map16_data)
            self.data_ptr = c_void_p(0)
            self.map16_data = c_void_p(0)
            self.freed = True

    def __del__(self):
        if not self.freed:
            if not self._constructed_from_raw:
                _pixi.sprite_free(self.data_ptr)
            if self.map16_data:
                _pixi.free_map16_buffer(self.map16_data)
            self.data_ptr = c_void_p(0)
            self.map16_data = c_void_p(0)
            self.freed = True

    @staticmethod
    def from_json(json_file: str) -> Sprite:
        spr: Sprite = Sprite(json_file)
        return spr

    @staticmethod
    def from_cfg(cfg_file: str) -> Sprite:
        spr: Sprite = Sprite(cfg_file)
        return spr
    
    @staticmethod
    def from_raw_ptr(data_ptr: c_void_p) -> Sprite:
        spr: Sprite = Sprite()
        spr.data_ptr = data_ptr
        spr._constructed_from_raw = True
        return spr

    def line(self) -> int:
        return int(_pixi.sprite_line(self.data_ptr))
    
    def number(self) -> int:
        return int(_pixi.sprite_number(self.data_ptr))
    
    def level(self) -> int:
        return int(_pixi.sprite_level(self.data_ptr))

    def sprite_table(self) -> SpriteTable:
        return SpriteTable(_pixi.sprites_sprite_table(self.data_ptr))

    def status_pointers(self) -> StatusPointers:
        return StatusPointers(_pixi.sprite_status_pointers(self.data_ptr))

    def extended_cape_ptr(self) -> int:
        return int(_pixi.extended_cape_ptr(self.data_ptr))

    def byte_count(self) -> int:
        return int(_pixi.sprite_byte_count(self.data_ptr))
    
    def extra_byte_count(self) -> int:
        return int(_pixi.sprite_extra_byte_count(self.data_ptr))
    
    def directory(self) -> str:
        size = c_int()
        cstr: bytes = _pixi.sprite_directory(self.data_ptr, byref(size))
        _check_cstr(cstr, size)
        return str(cstr, encoding="utf-8")
    
    def asm_file(self) -> str:
        size = c_int()
        cstr: bytes = _pixi.sprite_asm_file(self.data_ptr, byref(size))
        _check_cstr(cstr, size)
        return str(cstr, encoding="utf-8")
    
    def cfg_file(self) -> str:
        size = c_int()
        cstr: bytes = _pixi.sprite_cfg_file(self.data_ptr, byref(size))
        _check_cstr(cstr, size)
        return str(cstr, encoding="utf-8")
    
    def map_data(self) -> list[Map16]:
        size = c_int()
        ptr = _pixi.sprite_map_data(self.data_ptr, byref(size))
        map_data = []
        for i in range(int(size.value)):
            map_data.append(Map16(ptr[i]))
        _pixi.free_map16_array(ptr)
        return map_data
    
    def displays(self) -> list[Display]:
        size = c_int()
        ptr = _pixi.sprite_displays(self.data_ptr, byref(size))
        map_data = []
        for i in range(int(size.value)):
            map_data.append(Display(ptr[i]))
        _pixi.free_display_array(ptr)
        return map_data
    
    def collections(self) -> list[Collection]:
        size = c_int()
        ptr = _pixi.sprite_collections(self.data_ptr, byref(size))
        map_data = []
        for i in range(size.value):
            map_data.append(Collection(ptr[i]))
        _pixi.free_collection_array(ptr)
        return map_data

    def s16(self, map16_size: int = 0xFF) -> list[Map16]:
        if self._s16 is None:
            size: c_int = c_int()
            self._s16 = []
            self.map16_data = _pixi.create_map16_buffer(c_int(map16_size))
            raw_s16 = _pixi.generate_s16(self.data_ptr, self.map16_data, c_int(map16_size), byref(size), byref(self.map16_tile))
            for i in range(size.value):
                self._s16.append(Map16(raw_s16[i]))
        return self._s16
    
    def ssc(self, index: int = 0) -> str:
        self.s16()
        index_raw: c_int = c_int(index)
        cstr = _pixi.generate_ssc(self.data_ptr, index_raw, self.map16_tile)
        ssc = str(string_at(cstr), encoding="utf-8")
        _pixi.free_string(cstr)
        return ssc
    
    def mwt(self, index: int = 0) -> str:
        size: c_int = c_int()
        carr = _pixi.sprite_collections(self.data_ptr, byref(size))
        indexraw: c_int = c_int(min(index, size.value - 1))
        cstr = _pixi.generate_mwt(self.data_ptr, carr[indexraw.value], indexraw)
        _pixi.free_collection_array(carr)
        mwt = str(string_at(cstr), encoding="utf-8")
        _pixi.free_string(cstr)
        return mwt

    def mw2(self, index: int = 0) -> bytearray:
        size: c_int = c_int()
        carr = _pixi.sprite_collections(self.data_ptr, byref(size))
        indexraw: c_int = c_int(min(index, size.value - 1))
        mw2size: c_int = c_int()
        mw2raw = _pixi.generate_mw2(self.data_ptr, carr[indexraw.value], byref(mw2size))
        _pixi.free_collection_array(carr)
        mw2 = bytearray()
        for i in range(mw2size.value):
            mw2.append(mw2raw[i])
        _pixi.free_byte_array(mw2raw)
        return mw2
    
    def type(self) -> int:
        return int(_pixi.sprite_type(self.data_ptr))

class ParsedListResult:
    data_ptr: c_void_p
    freed: bool
    _success: bool

    def __init__(self, list_filename: str, per_level: bool = False):
        self.freed = False
        self._success = False
        cfilename = c_char_p(list_filename.encode())
        self.data_ptr = _pixi.parse_list_file(cfilename, c_bool(per_level))
        self._success = _pixi.list_result_success(self.data_ptr) != 0

    def success(self) -> bool:
        return self._success
    
    def sprite_array(self, sprite_type: ListType) -> list[Sprite]:
        size = c_int()
        ptr = _pixi.list_result_sprite_array(self.data_ptr, c_int(sprite_type.value), byref(size))
        sprites = []
        for i in range(int(size.value)):
            sprites.append(Sprite.from_raw_ptr(ptr[i]))
        return sprites

    def __enter__(self):
        return self
    
    def __exit__(self):
        if not self.freed:
            _pixi.list_result_free(self.data_ptr)
            self.data_ptr = c_void_p(0)
            self.freed = True

    def __del__(self):
        if not self.freed:
            _pixi.list_result_free(self.data_ptr)
            self.data_ptr = c_void_p(0)
            self.freed = True




def run(
    argv: list[str]
) -> int:
    """
    Run a PIXI program.

    :param argv: A list of strings, each of which is an argument to the PIXI program.
    :return: The return code of the PIXI program.
    """
    arguments = (c_char_p * len(argv))(*[arg.encode() for arg in argv])
    argc = c_int(len(argv))
    skip_first = c_bool(False)
    return int(_pixi.run(argc, arguments, skip_first))

def api_version() -> int:
    """
    Get the API version of the PIXI library.

    :return: The API version of the PIXI library.
    """
    return int(_pixi.api_version())


def check_api_version(edition: int, major: int, minor: int) -> bool:
    """
    Check the API version of the PIXI library.

    :param major: The major version number.
    :param minor: The minor version number.
    :param patch: The patch version number.
    :return: True if match False otherwise
    """
    return bool(
        _pixi.check_api_version(c_int(edition), c_int(major), c_int(minor))
    )

def last_error() -> str:
    """
    Get the last error message.
    :return: The last error message.
    """
    size = c_int()
    cstr: bytes = _pixi.last_error(byref(size))
    return str(cstr, encoding="utf-8")

def output() -> list[str]:
    """
    Get the output of the last PIXI program.
    :return: The output of the last PIXI program.
    """
    retval: list[str] = []
    size = c_int()
    cstr = _pixi.output(byref(size))
    for i in range(size.value):
        retval.append(str(cstr[i], encoding="utf-8"))
    return retval

