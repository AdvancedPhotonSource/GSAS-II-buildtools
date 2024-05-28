#!/usr/bin/env python
'''
* winLibs.py: Scan files and copy libraries *
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

    fileList = glob.glob(os.path.join(dirloc,'*.pyd'))
    fileList += glob.glob(os.path.join(dirloc,'*.exe'))
    print(f'Scanning {len(fileList)} files in {dirloc} for libraries to copy')
    
    libs = set([])
    ignorelist = []
    for f in fileList:
        cmd = ['ntldd',f]
        s = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                                 encoding='utf-8')
        out,err = s.communicate()
        print(f)
        if err:
            print(f,err)
            continue
        for i in out.split('\n')[1:]:
            print(i)
            if not i: continue
            if '=>' not in i: continue
            items = i.split()
            if len(items) < 3:
                print(i,'unparsed')
                continue
            if 'mingw' in i:
                libs.add(items[2])
                print('using',items[2])
            else:
                print('ignoring',items[2])
    for key in libs:
#        if 'libgcc' in key or 'libgfortran' in key or 'libquadmath' in key:
            shutil.copy(key,dirloc)
            print('copying\t',os.path.split(key)[1],'to',dirloc)
