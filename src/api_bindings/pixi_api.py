from __future__ import annotations
from ctypes import CDLL, POINTER, c_char, c_char_p, c_int, c_void_p, c_ubyte, byref
import sys

__all__ = ["run", "api_version", "check_api_version", "Sprite", "SpriteTable", "Tile", "StatusPointers", "Map8x8", "Map16", "Display", "Collection"]
_pixi = None

class _PixiDll:
    def __init__(self, dllname):
        dll = CDLL(dllname)
        self.dll = dll
        self.funcs = {}

    def setup_func(self, name, argtypes, restype):
        func = getattr(self.dll, "pixi_" + name)
        func.argtypes = argtypes
        func.restype = restype
        self.funcs[name] = func


def __init_pixi_dll():
    global _pixi
    if _pixi:
        return
    if sys.platform == "win32":
        _pixi = _PixiDll("./pixi_api.dll")
    elif sys.platform == "darwin":
        _pixi = _PixiDll("./libpixi_api.dylib")
    else:
        _pixi = _PixiDll("./libpixi_api.so")

    _pixi.setup_func("run", [c_int, POINTER(c_char_p)], c_int)
    _pixi.setup_func("api_version", [], c_int)
    _pixi.setup_func("check_api_version", [c_int, c_int, c_int], c_int)
    _pixi.setup_func("parse_json_sprite", [c_char_p], c_void_p)
    _pixi.setup_func("parse_cfg_sprite", [c_char_p], c_void_p)
    _pixi.setup_func("sprite_free", [c_void_p], None)
    _pixi.setup_func("free_map16_array", [c_void_p], None)
    _pixi.setup_func("free_display_array", [c_void_p], None)
    _pixi.setup_func("free_collection_array", [c_void_p], None)
    _pixi.setup_func("free_tile_array", [c_void_p], None)

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

    _pixi.setup_func("map8x8_tile", [c_void_p], c_char)
    _pixi.setup_func("map8x8_prop", [c_void_p], c_char)

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

__init_pixi_dll()

class Tile:
    data_ptr: c_void_p
    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def x_offset(self) -> int:
        return int(_pixi.funcs["tile_x_offset"](self.data_ptr))
    
    def y_offset(self) -> int:
        return int(_pixi.funcs["tile_y_offset"](self.data_ptr))
    
    def tile_number(self) -> int:
        return int(_pixi.funcs["tile_tile_number"](self.data_ptr))
    
    def text(self) -> str:
        size = c_int()
        cstr: c_char_p = _pixi.funcs["tile_text"](self.data_ptr, byref(size))
        assert(len(cstr) == size.value)
        return str(cstr, encoding="ascii")

class SpriteTable:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def type(self) -> int:
        return int(_pixi.funcs["sprite_table_type"](self.data_ptr))
    
    def actlike(self) -> int:
        return int(_pixi.funcs["sprite_table_actlike"](self.data_ptr))
    
    def tweak(self) -> bytearray:
        size = c_int()
        ptr: POINTER(c_ubyte) = _pixi.funcs["sprite_table_tweak"](self.data_ptr, byref(size))
        tweaks = bytearray()
        for i in range(int(size.value)):
            tweaks.append(ptr[i])
        return tweaks
    
    def init(self) -> int:
        return int(_pixi.funcs["sprite_table_init"](self.data_ptr))
    
    def main(self) -> int:
        return int(_pixi.funcs["sprite_table_main"](self.data_ptr))
    
    def extra(self) -> bytearray:
        size = c_int()
        ptr: POINTER(c_ubyte) = _pixi.funcs["sprite_table_extra"](self.data_ptr, byref(size))
        extras = bytearray()
        for i in range(int(size.value)):
            extras.append(ptr[i])
        return extras

class StatusPointers:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def carriable(self) -> int:
        return int(_pixi.funcs["status_pointers_carriable"](self.data_ptr))
    
    def carried(self) -> int:
        return int(_pixi.funcs["status_pointers_carried"](self.data_ptr))
    
    def kicked(self) -> int:
        return int(_pixi.funcs["status_pointers_kicked"](self.data_ptr))
    
    def mouth(self) -> int:
        return int(_pixi.funcs["status_pointers_mouth"](self.data_ptr))
    
    def goal(self) -> int:
        return int(_pixi.funcs["status_pointers_goal"](self.data_ptr))

class Map8x8:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def tile(self) -> int:
        return int(_pixi.funcs["map8x8_tile"](self.data_ptr))
    
    def prop(self) -> int:
        return int(_pixi.funcs["map8x8_prop"](self.data_ptr))

class Map16:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def top_left(self) -> Map8x8:
        return Map8x8(_pixi.funcs["map16_top_left"](self.data_ptr))
    
    def top_right(self) -> Map8x8:
        return Map8x8(_pixi.funcs["map16_top_right"](self.data_ptr))
    
    def bottom_left(self) -> Map8x8:
        return Map8x8(_pixi.funcs["map16_bottom_left"](self.data_ptr))
    
    def bottom_right(self) -> Map8x8:
        return Map8x8(_pixi.funcs["map16_bottom_right"](self.data_ptr))

class Display:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def description(self) -> str:
        size = c_int()
        cstr: c_char_p = _pixi.funcs["display_description"](self.data_ptr, byref(size))
        assert(len(cstr) == size.value)
        return str(cstr, encoding="ascii")
    
    def tiles(self) -> list[Tile]:
        size = c_int()
        ptr: POINTER(c_void_p) = _pixi.funcs["display_tiles"](self.data_ptr, byref(size))
        tiles = []
        for i in range(int(size.value)):
            tiles.append(Tile(ptr[i]))
        return tiles

    def extra_bit(self) -> int:
        return int(_pixi.funcs["display_extra_bit"](self.data_ptr))
    
    def x(self) -> int:
        return int(_pixi.funcs["display_x"](self.data_ptr))
    
    def y(self) -> int:
        return int(_pixi.funcs["display_y"](self.data_ptr))

class Collection:
    data_ptr: c_void_p

    def __init__(self, data_ptr: c_void_p):
        self.data_ptr = data_ptr
    
    def name(self) -> str:
        size = c_int()
        cstr: c_char_p = _pixi.funcs["collection_name"](self.data_ptr, byref(size))
        assert(len(cstr) == size.value)
        return str(cstr, encoding="ascii")
    
    def extra_bit(self) -> int:
        return int(_pixi.funcs["collection_extra_bit"](self.data_ptr))
    
    def prop(self) -> bytearray:
        size = c_int()
        ptr: POINTER(c_ubyte) = _pixi.funcs["collection_prop"](self.data_ptr, byref(size))
        props = bytearray()
        for i in range(int(size.value)):
            props.append(ptr[i])
        return props

class Sprite:
    data_ptr: c_void_p
    freed: bool

    def __init__(self, filename: str):
        self.freed = False
        cfilename = c_char_p(filename.encode())
        if filename.endswith(".json"):
            self.data_ptr = _pixi.funcs["parse_json_sprite"](cfilename)
        elif filename.endswith(".cfg"):
            self.data_ptr = _pixi.funcs["parse_cfg_sprite"](cfilename)
        else:
            raise ValueError("Unknown sprite file extension")

    def __enter__(self):
        return self
    
    def __exit__(self):
        if not self.freed:
            _pixi.funcs["sprite_free"](self.data_ptr)
            self.data_ptr = c_void_p(0)
            self.freed = True

    def __del__(self):
        if not self.freed:
            _pixi.funcs["sprite_free"](self.data_ptr)
            self.data_ptr = c_void_p(0)
            self.freed = True

    @staticmethod
    def from_json(json_file: str) -> Sprite:
        spr: Sprite = Sprite(json_file)
        return spr

    @staticmethod
    def from_cfg(cfg_file: str) -> Sprite:
        spr: Sprite = Sprite(cfg_file)
        return spr

    def line(self) -> int:
        return int(_pixi.funcs["sprite_line"](self.data_ptr))
    
    def number(self) -> int:
        return int(_pixi.funcs["sprite_number"](self.data_ptr))
    
    def level(self) -> int:
        return int(_pixi.funcs["sprite_level"](self.data_ptr))

    def sprite_table(self) -> SpriteTable:
        return SpriteTable(_pixi.funcs["sprites_sprite_table"](self.data_ptr))

    def status_pointers(self) -> StatusPointers:
        return StatusPointers(_pixi.funcs["sprite_status_pointers"](self.data_ptr))

    def extended_cape_ptr(self) -> int:
        return int(_pixi.funcs["extended_cape_ptr"](self.data_ptr))

    def byte_count(self) -> int:
        return int(_pixi.funcs["sprite_byte_count"](self.data_ptr))
    
    def extra_byte_count(self) -> int:
        return int(_pixi.funcs["sprite_extra_byte_count"](self.data_ptr))
    
    def directory(self) -> str:
        size = c_int()
        cstr: c_char_p = _pixi.funcs["sprite_directory"](self.data_ptr, byref(size))
        assert(len(cstr) == size.value)
        return str(cstr, encoding="ascii")
    
    def asm_file(self) -> str:
        size = c_int()
        cstr: c_char_p = _pixi.funcs["sprite_asm_file"](self.data_ptr, byref(size))
        assert(len(cstr) == size.value)
        return str(cstr, encoding="ascii")
    
    def cfg_file(self) -> str:
        size = c_int()
        cstr: c_char_p = _pixi.funcs["sprite_cfg_file"](self.data_ptr, byref(size))
        assert(len(cstr) == size.value)
        return str(cstr, encoding="ascii")
    
    def map_data(self) -> list[Map16]:
        size = c_int()
        ptr: POINTER(c_void_p) = _pixi.funcs["sprite_map_data"](self.data_ptr, byref(size))
        map_data = []
        for i in range(int(size.value)):
            map_data.append(Map16(ptr[i]))
        _pixi.funcs["free_map16_array"](ptr)
        return map_data
    
    def displays(self) -> list[Display]:
        size = c_int()
        ptr: POINTER(c_void_p) = _pixi.funcs["sprite_displays"](self.data_ptr, byref(size))
        map_data = []
        for i in range(int(size.value)):
            map_data.append(Display(ptr[i]))
        _pixi.funcs["free_display_array"](ptr)
        return map_data
    
    def collections(self) -> list[Collection]:
        size = c_int()
        ptr: POINTER(c_void_p) = _pixi.funcs["sprite_collections"](self.data_ptr, byref(size))
        map_data = []
        for i in range(int(size.value)):
            map_data.append(Collection(ptr[i]))
        _pixi.funcs["free_collection_array"](ptr)
        return map_data
    
    def type(self) -> int:
        return int(_pixi.funcs["sprite_type"](self.data_ptr))

def run(
    argv: list[list[str]]
) -> int:
    """
    Run a PIXI program.

    :param argv: A list of strings, each of which is an argument to the PIXI program.
    :return: The return code of the PIXI program.
    """
    argv = (c_char_p * len(argv))(*[arg.encode() for arg in argv])
    argc = c_int(len(argv))
    return int(_pixi.funcs["run"](argc, argv))


def api_version() -> int:
    """
    Get the API version of the PIXI library.

    :return: The API version of the PIXI library.
    """
    return int(_pixi.funcs["api_version"]())


def check_api_version(edition: int, major: int, minor: int) -> bool:
    """
    Check the API version of the PIXI library.

    :param major: The major version number.
    :param minor: The minor version number.
    :param patch: The patch version number.
    :return: True if match False otherwise
    """
    return bool(
        _pixi.funcs["check_api_version"](c_int(edition), c_int(major), c_int(minor))
    )
