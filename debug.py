#!/bin/env python3

from sys import platform, argv
from subprocess import run
from shutil import which

windows = platform.startswith('win')

def cmd(*args, **kwargs):
    print(" ".join(args))
    return run(args, check=True, **kwargs)

if __name__ == '__main__':
    out_path = './ATom' + ('.exe' if windows else '')
    
    src_dir = 'Source'
    flags = ['-debug', '-keep-executable', f'-out:{out_path}', *argv[1:]]

    if which('gdb') is not None:
        print('GDB found, running with GDB')
        cmd('odin', 'build', src_dir, *flags)
        cmd('gdb', '-ex', 'run', out_path)
    else:
        print('GDB not found, running without GDB')
        cmd('odin', 'run', src_dir, *flags)
