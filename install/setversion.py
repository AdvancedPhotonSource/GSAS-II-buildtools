import sys
import platform
import subprocess

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
svn = 'svn' # assume in path
cmd = [svn,'info','https://subversion.xray.aps.anl.gov/pyGSAS/trunk']
s = subprocess.Popen(cmd,
                    stdout=subprocess.PIPE,stderr=subprocess.PIPE)
out,err = MakeByte2str(s.communicate())
if err:
    print ('subversion error!\nout=%s'%out)
    print ('err=%s'%err)
    sys.exit(1)
for line in out.split('\n'):
    if line.startswith('Rev'):
        version = line.split()[1].strip()
        break
else:
    print ('Version not found!\nout=%s'%out)
    sys.exit(1)

import numpy as np
import wx
import matplotlib as mpl
import platform
npversion = np.__version__[:np.__version__.find('.',2)]
#wxversion = wx.__version__[:wx.__version__.find('.',2)]
wxversion = wx.__version__
mplversion = mpl.__version__[:mpl.__version__.find('.',2)]
pyversion = platform.python_version()
if pyversion.find('.',2) > 0: pyversion = pyversion[:pyversion.find('.',2)]
print ('SVN version is    {}'.format(version))
print ('python version is {}'.format(pyversion))
print ('numpy version is  {}'.format(npversion))
print ('wx version is     {}'.format(wxversion))
print ('MPL version is    {}'.format(mplversion))

for fil in ('g2complete/meta.yaml','g2complete/build.sh',
                'g2complete/bld.bat',
                'g2full/construct.yaml',
                'g2full/g2postinstall.bat',
                'g2full/g2postinstall.sh',
                ):
    try:
        if platform.machine() == 'aarch64': # Raspberry Pi
            note = 'for Raspberry Pi OS'
            fp = open(fil+'.Pitemplate','r')
        else:
            note = ''
            fp = open(fil+'.template','r')
        out = fp.read().replace('**Version**',version)
        fp.close()
    except FileNotFoundError:
        print('Skipping ',fil)
        continue
    if sys.platform == "win32" and platform.architecture()[0] != '64bit':
        if 'win-64' in out:
            print('changing for 32-bit windows')
            out = out.replace('win-64','win-32')
    if sys.platform.startswith("linux") and platform.architecture()[0] != '64bit':
        if 'linux-64' in out:
            print('changing for 32-bit linux')
            out = out.replace('linux-64','linux-32')
    out = out.replace('**pyversion**',pyversion)
    out = out.replace('**npversion**',npversion)
    out = out.replace('**wxversion**',wxversion)
    out = out.replace('**mplversion**',mplversion)
    if sys.platform == "darwin": out.replace('#MACOnly#','')
    print('Creating',fil,note)
    fp = open(fil,'w')
    fp.write(out)
    fp.close()
    
