#!/bin/env python3

from sys import platform, argv
from subprocess import run
from os import path, remove, rename
from urllib.request import urlopen
from hashlib import sha3_256
from io import BytesIO
from zipfile import ZipFile
from shutil import rmtree

windows = platform.startswith('win')

def cmd(*args, **kwargs):
    print(" ".join(args))
    return run(args, check=True, **kwargs)

def download_sqlite():
    print('downloading sqlite')

    AMALGAMATION = 'sqlite-amalgamation-3500400'
    URL = f'https://sqlite.org/2025/{AMALGAMATION}.zip'

    data = urlopen(URL).read()
    sha = sha3_256()
    sha.update(data)
    assert(sha.hexdigest() == 'f131b68e6ba5fb891cc13ebb5ff9555054c77294cb92d8d1268bad5dba4fa2a1')

    ZipFile(BytesIO(data)).extractall()
    rename(f'{AMALGAMATION}/sqlite3.c', source)
    rmtree(AMALGAMATION)

    print('finished downloading sqlite')

if __name__ == '__main__':
    sqlite = 'sqlite/sqlite'
    source = sqlite+'3'+'.c'

    if not path.exists(source):
        download_sqlite()

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
    print('finished building sqlite')
