from ctypes import CDLL, POINTER, c_char, c_char_p, c_int
import sys

__all__ = ["run", "api_version", "check_api_version"]
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

    _pixi.setup_func("run", [c_int, POINTER(c_char_p), c_char_p, c_char_p], c_int)
    _pixi.setup_func("api_version", [], c_int)
    _pixi.setup_func("check_api_version", [c_int, c_int, c_int], c_int)


__init_pixi_dll()


def run(
    argv: list[list[str]], stdin_file: str = None, stdout_file: str = None
) -> int:
    """
    Run a PIXI program.

    :param argv: A list of strings, each of which is an argument to the PIXI program.
    :param stdin_file: The name of the file to use for stdin.
    :param stdout_file: The name of the file to use for stdout.
    :return: The return code of the PIXI program.
    """
    argv = (c_char_p * len(argv))(*[arg.encode() for arg in argv])
    argc = c_int(len(argv))
    stdin_file = c_char_p(stdin_file.encode()) if stdin_file else c_char_p()
    stdout_file = c_char_p(stdout_file.encode()) if stdout_file else c_char_p()
    return int(_pixi.funcs["run"](argc, argv, stdin_file, stdout_file))


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
