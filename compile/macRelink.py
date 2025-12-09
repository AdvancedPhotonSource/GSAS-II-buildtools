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
    print('Running macRelink to resolve .dylib references')
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
    print('Scanning for referenced libraries')
    for f in fileList:
        cmd = ['otool','-L',f]
        s = subprocess.Popen(cmd,encoding='UTF-8',
                    stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        out,err = s.communicate()
        print('\n\nprocessing=',f)
        for i in out.split('\n')[1:]: 
            if not i: continue
            lib = i.split()[0]
            if os.path.split(lib)[0] == "/usr/lib": # ignore items in system library (usually libSystem.B.dylib)
                if "libSystem" not in lib: print("ignoring ",lib)
                continue
            if "@rpath" in lib and lib not in ignorelist:
                ignorelist.append(lib)
                print("@rpath ignoring ",lib)
                continue
            elif "/" not in lib and lib not in ignorelist:
                ignorelist.append(lib)
                print("no / ignoring ",lib)
                continue
            if os.path.split(lib)[1] == os.path.split(f)[1]:
                continue  # don't act on reference to current file
            if lib not in libs:
                print('copying',lib)
                libs[lib] = []
                if os.path.exists(lib):
                    newname = os.path.join(dirloc,os.path.split(lib)[1])
                    shutil.copy(lib,newname)
                    print('library copied',lib,'to',newname)
                    fileList.append(newname)
                    if 'libgfortran' in lib:
                        # libquadmath needed by libgfortran
                        g = os.path.join(os.path.split(lib)[0],'*libquadmath*dylib')
                        for f1 in glob.glob(g):
                            shutil.copy(f1,dirloc)
                            print('library copied',f1,'to',dirloc)
                else:
                    print('library not found',lib)
                libs[lib].append(f)
    print('Referenced libraries:',', '.join(libs.keys()))
    #print(libs)
    for key in libs:
        newkey = os.path.join('@rpath',os.path.split(key)[1])
        print('Fixing',key,'to',newkey)
        # if os.path.exists(key):
        #     shutil.copy(key,dirloc)
        # else:
        #     print('skipping copy of library',key)
        for f in libs[key]:
            print('\t in',os.path.split(f)[1])
            cmd = ["install_name_tool","-change",key,newkey,f]
            s = subprocess.Popen(cmd,encoding='UTF-8',
                                     stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE)
            out,err = s.communicate()
            if err:
                print('error running',' '.join(cmd))
                print(out)
                print(err)
