'''Generate the name for a tar file with binaries for the current Python
and numpy versions, as in "mac_arm_p3.11_n1.26.tgz"
'''
import sys
import os
import platform
import numpy as np

def GetBinaryPrefix(pyver=None):
    '''Creates the first part of the binary directory name
    such as linux_64_p3.9 (where the full name will be
    linux_64_p3.9_n1.21).

    Note that any change made here is also needed in GetBinaryDir in
    fsource/SConstruct
    '''
    if sys.platform == "win32":
        prefix = 'win'
    elif sys.platform == "darwin":
        prefix = 'mac'
    elif sys.platform.startswith("linux"):
        prefix = 'linux'
    else:
        print(u'Unknown platform: '+sys.platform)
        raise Exception('Unknown platform')
    if 'arm' in platform.machine() and sys.platform == "darwin":
        bits = 'arm'
    elif 'aarch' in platform.machine() and '64' in platform.architecture()[0]:
        bits = 'arm64'
    elif 'arm' in platform.machine():
        bits = 'arm32'
    elif '64' in platform.architecture()[0]:
        bits = '64'
    else:
        bits = '32'

    # format current python version
    if pyver:
        pyver = 'p'+pyver
    else:
        pyver = 'p{}.{}'.format(*sys.version_info[0:2])

    return '_'.join([prefix,bits,pyver])

print(f'{GetBinaryPrefix()}_n{np.__version__.rsplit(".",1)[0]}.tgz')
