#!/usr/bin/env python
'''
*macRelink: Remove hardcoded library references*
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
    
    libs = {}
    ignorelist = []
    for f in fileList:
        cmd = ['otool','-L',f]
        s = subprocess.Popen(cmd,encoding='UTF-8',
                    stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        out,err = s.communicate()
        for i in out.split('\n')[1:]: 
            if not i: continue
            lib = i.split()[0]
            if os.path.split(lib)[0] == "/usr/lib": # ignore items in system library (usually libSystem.B.dylib)
                if "libSystem" not in lib: print("ignoring ",lib)
                continue
            if "@rpath" in lib and lib not in ignorelist:
                ignorelist.append(lib)
                print("ignoring ",lib)
                continue
            elif "/" not in lib and lib not in ignorelist:
                ignorelist.append(lib)
                print("ignoring ",lib)
                continue
            if lib not in libs:
                libs[lib] = []
            libs[lib].append(f)
    for key in libs:
        newkey = os.path.join('@rpath',os.path.split(key)[1])
        print('Fixing',key,'to',newkey)
        if os.path.exists(key):
            shutil.copy(key,dirloc)
        else:
            print('skipping copy of',key)
        for f in libs[key]:
            print('\t',os.path.split(f)[1])
            cmd = ["install_name_tool","-change",key,newkey,f]
            print(' '.join(cmd))
            s = subprocess.Popen(cmd,encoding='UTF-8',
                                     stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE)
            out,err = s.communicate()
            if err:
                print(out)
                print(err)
