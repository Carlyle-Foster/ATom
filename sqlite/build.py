#!/bin/env python3

from sys import platform, argv
from subprocess import run
from os import path, remove

windows = platform.startswith('win')

def cmd(*args, **kwargs):
    print(" ".join(args))
    return run(args, check=True, **kwargs)

if __name__ == '__main__':
    sqlite = 'sqlite/sqlite'
    source = sqlite+'3'+'.c'

    obj = sqlite + ('.obj' if windows else '.o')
    lib = sqlite + ('.lib' if windows else '.a')

    print('building sqlite')
    try:
        if windows:
            cmd('cl', '/c', source, f'/Fo{obj}', *argv[1:])
            cmd('lib', obj, f'/OUT:{lib}')
        else:
            cmd('cc', '-c', source, '-o', obj, *argv[1:])
            cmd('ar', 'rcs', lib, obj)
    finally:
        if path.exists(obj):
            remove(obj)
    print('built sqlite')
