#!/usr/bin/env python
'''
* linuxLibs.py: Scan files and copy libraries *
===================================================

'''
from __future__ import division, print_function
import sys, os, glob, subprocess, shutil
#os.path, stat, plistlib
def Usage():
    print("\n\tUsage: python "+sys.argv[0]+" <binary-dir>\n")
    sys.exit()


if __name__ == '__main__':
    if len(sys.argv) == 2:
        dirloc = os.path.abspath(sys.argv[1])
    else:
        Usage()
        raise Exception

    fileList = glob.glob(os.path.join(dirloc,'*.so'))
    fileList += glob.glob(os.path.join(dirloc,'convcell'))
    fileList += glob.glob(os.path.join(dirloc,'LATTIC'))
    fileList = glob.glob(os.path.join(dirloc,'zi*'))
    
    libs = set([])
    ignorelist = []
    for f in fileList:
        cmd = ['ldd',f]
        s = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                                 encoding='utf-8')
        out,err = s.communicate()
        print(f)
        for i in out.split('\n')[1:]:
            if not i: continue
            if '=>' not in i: continue
            items = i.split()
            if len(items) < 3: continue
            lib = items[2]
            libs.add(items[2])
            continue
            # if os.path.split(lib)[0] == "/usr/lib": # ignore items in system library (usually libSystem.B.dylib)
            #     if "libSystem" not in lib: print("ignoring ",lib)
            #     continue
            # if "@rpath" in lib and lib not in ignorelist:
            #     ignorelist.append(lib)
            #     print("ignoring ",lib)
            #     continue
            # elif "/" not in lib and lib not in ignorelist:
            #     ignorelist.append(lib)
            #     print("ignoring ",lib)
            #     continue
            # if lib not in libs:
            #     libs[lib] = []
            # libs[lib].append(f)
    for key in libs:
        shutil.copy(key,dirloc)
        print('copying\t',os.path.split(key)[1],'to',dirloc)
