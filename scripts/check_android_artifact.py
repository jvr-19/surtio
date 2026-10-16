#!/usr/bin/env python3
"""Check 64-bit ELF LOAD alignment inside an APK/AAB; not a runtime test."""
import argparse
import struct
import zipfile
from pathlib import Path


def check(path):
    checked = 0
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if not name.endswith('.so'):
                continue
            data = archive.read(name)
            if data[:4] != b'\x7fELF':
                raise ValueError(f'Invalid native library: {name}')
            if data[4] != 2:  # Android's 16 KB requirement concerns 64-bit libraries.
                continue
            endian = '<' if data[5] == 1 else '>'
            phoff = struct.unpack_from(endian + 'Q', data, 32)[0]
            entry_size, count = struct.unpack_from(endian + 'HH', data, 54)
            for index in range(count):
                start = phoff + entry_size * index
                if struct.unpack_from(endian + 'I', data, start)[0] != 1:
                    continue
                offset, address = struct.unpack_from(endian + 'QQ', data, start + 8)
                align = struct.unpack_from(endian + 'Q', data, start + 48)[0]
                if align < 16384 or (address - offset) % 16384:
                    raise ValueError(f'64-bit LOAD segment is not 16 KB aligned: {name}')
            checked += 1
    if not checked:
        raise ValueError('No 64-bit native libraries found')
    print(f'{Path(path).name}: {checked} 64-bit libraries pass ELF 16 KB alignment. Runtime test still required.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('artifact', type=Path)
    check(parser.parse_args().artifact)
