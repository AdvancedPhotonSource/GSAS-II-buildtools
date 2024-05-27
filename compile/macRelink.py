#!/usr/bin/env python
'''
*macRelink: Remove hardcoded library references*
===================================================

'''
from __future__ import division, print_function
import sys, os, glob, subprocess
#os.path, stat, shutil, subprocess, plistlib
def Usage():
    print("\n\tUsage: python "+sys.argv[0]+" <binary-dir> (or)")
    print("\n\tUsage: python "+sys.argv[0]+"\n")
    sys.exit()
    
def MakeByte2str(arg):
    '''Convert output from subprocess pipes (bytes) to str (unicode) in Python 3.
    In Python 2: Leaves output alone (already str). 
    Leaves stuff of other types alone (including unicode in Py2)
    Works recursively for string-like stuff in nested loops and tuples.

    typical use::

        out = MakeByte2str(out)

    or::

        out,err = MakeByte2str(s.communicate())
    
    '''
    if isinstance(arg,str): return arg
    if isinstance(arg,bytes): return arg.decode()
    if isinstance(arg,list):
        return [MakeByte2str(i) for i in arg]
    if isinstance(arg,tuple):
        return tuple([MakeByte2str(i) for i in arg])
    return arg

if __name__ == '__main__':
    if len(sys.argv) == 2:
        dirloc = os.path.abspath(sys.argv[1])
    elif len(sys.argv) == 1:
        dirloc = os.path.abspath(os.getcwd())
    else:
        Usage()
        raise Exception

    fileList = [os.path.join(dirloc,'bin/svn')] + glob.glob(os.path.join(dirloc,'lib/*.dylib'))
        
    libs = {}
    ignorelist = []
    fixedlist = []
    overridelist = []
    for f in fileList:
        cmd = ['otool','-L',f]
        s = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        out,err = MakeByte2str(s.communicate())
        for i in out.split('\n')[1:]: 
            if not i: continue
            libloc = i.split()[0]
            if libloc.startswith("/System"): # ignore items in system libraries
                if libloc not in ignorelist: ignorelist.append(libloc)
            elif libloc.startswith("/usr/lib"):
                if os.path.exists(
                        os.path.join(dirloc,'all_dy',os.path.split(libloc)[1])):
                    if libloc not in libs: libs[libloc] = []
                    libs[libloc].append(f)
                    overridelist.append(libloc)
                else: # ignore this
                    l = os.path.split(libloc)[1]
                    if l not in ignorelist: ignorelist.append(l) 
            elif "@rpath" in libloc:
                if libloc not in fixedlist: fixedlist.append(libloc)
            else:
                if libloc not in libs: libs[libloc] = []
                libs[libloc].append(f)

    for key in libs:
        newkey = os.path.join('@rpath',os.path.split(key)[1])
        print('Fixing',key,'to @rpath in')
        for f in libs[key]:
            print('\t',os.path.split(f)[1])
            cmd = ["install_name_tool","-change",key,newkey,f]
            #print(cmd)
            s = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            out,err = MakeByte2str(s.communicate())

    print('System libs',ignorelist)
    print('Already fixed',[os.path.split(f)[1] for f in fixedlist])
    print('anaconda lib overrides',[os.path.split(f)[1] for f in overridelist])

    for key in libs.keys()+overridelist+fixedlist:
        libnam = os.path.split(key)[1]
        if os.path.exists(os.path.join(dirloc,'lib',libnam)):
            pass
        elif os.path.exists(os.path.join(dirloc,'all_dy',libnam)):
            cmd = ["cp","-p",os.path.join(dirloc,'all_dy',libnam),'lib/']
            # cp -p all_dy/libsvn_client-1.0.dylib lib
            print(libnam, 'being copied')
            s = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            out,err = MakeByte2str(s.communicate())
        else:
            print(libnam, 'needed')
    print('Adding rpath hint to bin/svn')
    cmd = ['install_name_tool','-add_rpath','@executable_path/../lib',os.path.join(dirloc,'bin/svn')]
    s = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err = MakeByte2str(s.communicate())
