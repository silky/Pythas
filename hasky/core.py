from importlib.abc import Loader, MetaPathFinder
from importlib.util import spec_from_file_location
from subprocess import run
from ctypes import cdll
from functools import partial
from sys import meta_path, platform
import os.path

from .haskell.ghc import GHC_VERSION, ghc_compile_cmd
from .haskell.parse_file import parse_haskell
from .haskell.ffi import create_ffi_file
from .utils import custom_attr_getter, findSource, DOT

from importlib.abc import MetaPathFinder

class HaskyMetaFinder(MetaPathFinder):
    def find_spec(self, fullname, path, target=None):
        if path is None:
            path = [os.getcwd()]

        if DOT in fullname:
            *_,name = fullname.split(DOT)
        else:
            name = fullname
            
        for p in path:
            # let's assume it's a python module
            subname = os.path.join(p, name)
            if os.path.isdir(subname):
                filename = os.path.join(subname,'__init__.py')
            else:
                filename = subname + '.py'
            # and check if this module exists
            if not os.path.exists(filename):
                # in case it doesn't look for a haskell file of that name
                for haskellfile in findSource(name, p):
                    return spec_from_file_location(fullname, p, loader=HaskyLoader(haskellfile),
                        submodule_search_locations=None)

        # Let the other finders handle this
        return None

class HaskyLoader(Loader):
    def __init__(self, filename):
        self.filename = filename

    def create_module(self, spec):
        return None

    def exec_module(self, module):
        parse_info = parse_haskell(self.filename)
        ffi_files = create_ffi_file(self.filename, parse_info)
        libs = [(cdll.LoadLibrary(libname),info)
            for libname,info in create_shared_libs(ffi_files)]
        setattr(module, 'ffi_libs', libs)
        module.__getattr__ = partial(custom_attr_getter, module)

def create_shared_libs(ffi_files):
    yield from (ghc_compile(fn, info) for fn,info in ffi_files)

def ghc_compile(filename, parse_info):
    filedir = parse_info.dir
    name = parse_info.name.lower()
    libname = os.path.join(filedir,'lib'+name)
    if platform.startswith('linux'):
        libname += '.so'
    elif platform.startswith('win32'):
        libname += '.dll'
    cmd = ghc_compile_cmd(filename, libname, filedir, platform)
    run(cmd)
    return libname, parse_info

def install():
    meta_path.insert(0, HaskyMetaFinder())