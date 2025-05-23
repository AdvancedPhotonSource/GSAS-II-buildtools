# this creates the files needed to build the GSAS2main conda package
# and the GSAS2main self-installer from the main branch

import os
import sys
import platform
import git
import requests

BASE_HEADER = {'Accept': 'application/vnd.github+json',
               'X-GitHub-Api-Version': '2022-11-28'}
G2binURL = "https://api.github.com/repos/AdvancedPhotonSource/GSAS-II-buildtools"
G2url="https://github.com/AdvancedPhotonSource/GSAS-II.git"
# location where conda build output files are written
bldloc = os.path.normpath(os.path.dirname(__file__))
branch='main'

def GetBinaryPrefix():
    '''Creates the first part of the binary directory name
    such as linux_64. 

    Based on similar routine in GSASIIpath
    '''
    if sys.platform == "win32":
        prefix = 'win'
    elif sys.platform == "darwin":
        prefix = 'mac'
    elif sys.platform.startswith("linux"):
        prefix = 'linux'
    else:
        print(f'Unknown platform: {sys.platform}')
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
    return '_'.join([prefix,bits])

def getGitBinaryReleases(cache=False):
    '''Retrieves the binaries and download urls of the latest release

    :param bool cache: when cache is True and the binaries file names
       are retrieved (does not always succeed when done via GitHub
       Actions), the results are saved in a file for reuse should the
       retrieval fail. Default is False so the file is not changed.

    :returns: a URL dict for GSAS-II binary distributions found in the newest
      release in a GitHub repository. The repo location is defined in global
      `G2binURL`.

      The dict keys are references to binary distributions, which are named
      as f"{platform}_p{pver}_n{npver}" where platform is determined
      in :func:`GSASIIpath.GetBinaryPrefix` (linux_64, mac_arm, win_64,...)
      and where `pver` is the Python version (such as "3.10") and `npver` is
      the numpy version (such as "1.26").

      The value associated with each key contains the full URL to
      download a tar containing that binary distribution.
    '''
    try:
        import requests
    except:
        print('Unable to install binaries in getGitBinaryReleases():\n requests module not available')
        return
    # Get first page of releases. (Could there be more than one?)
    releases = []
    tries = 0
    while tries < 5: # this has been known to fail, so retry
        tries += 1
        releases = requests.get(
            url=f"{G2binURL}/releases",
            headers=BASE_HEADER
        ).json()
        try:
            # loop over assets of latest release (will [-1] always get this?)
            versions = []
            URLs = []
            for asset in releases[-1]['assets']:
                if not asset['name'].endswith('.tgz'): continue
                versions.append(asset['name'][:-4]) # Remove .tgz tail
                URLs.append(asset['browser_download_url'])
            count = len(versions)
            # Cache the binary releases for later use in case GitHub
            # prevents us from using a query to get them
            if cache and count > 4:
                fp = open(os.path.join(path2GSAS2,'inputs','BinariesCache.txt'),'w')
                res = dict(zip(versions,URLs))
                for key in res:
                    fp.write(f'{key} : {res[key]}\n')
                fp.close()
            return dict(zip(versions,URLs))
        except:
            print('Attempt to get GSAS-II binary releases/assets failed, sleeping for 10 sec and then retrying')
            import time
            time.sleep(10)  # this does not seem to help when GitHub is not letting the queries through

    print(f'Could not get releases from {G2binURL}. Using cache')
    URL = 'https://raw.githubusercontent.com/AdvancedPhotonSource/GSAS-II/refs/heads/main/GSASII/inputs/BinariesCache.txt'
    res = {}
    try:
        r = requests.get(URL, allow_redirects=True)
        for line in r.text.split('\n'):
            print(line) # debug
            key,val = line.split(':',1)[:2]
            res[key.strip()] = val.strip()
        fp.close()
        return res
    except:
        print('Cache read of releases failed too.')
        return None

def getNewestVersions():
    '''get the latest Python & numpy versions with supplied binaries, 
    as well as the latest numerical tag name used in the GSAS-II repo

    :returns: version, maxpystr, maxnpstr or None, where 
      * version: GSAS-II numerical version number
      * maxpystr: latest supported Python version (x.y)
      * maxnpstr: latest supported numpy version (x.y)
    '''
    
    binaries = getGitBinaryReleases()
    if binaries is None:
        print('No binaries found!')
        binaries = []
    prefix = GetBinaryPrefix()

    # these command gets the latest numerical tag in most recent entries in the branch
    import os,tempfile,shutil
    tpath = os.path.join(tempfile.gettempdir(),'git-tmp')
    r = git.Repo.clone_from(G2url,branch=branch,depth=100,to_path=tpath)
    tags = [tag.name for tag in r.tags] # get all the tags
    r.close() # clean up
    try:
        shutil.rmtree(tpath)
    except:  # since a tempfile, will get cleaned up eventually anyway...
        pass
    version = sorted([i for i in tags if i.isdecimal()],key=int)[-1]

    # get max python release #
    maxpy = 0
    maxpystr = None
    maxnpstr = None
    for j in [i for i in binaries if i.startswith(prefix)]:
        s = j.split('_p')[1].split('_n')[0]
        try:
            if float(s) > maxpy:
                maxpy = float(s)
                maxpystr = s
        except ValueError:
            pass
    if maxpystr is None:
        print('No Python version found')
    else:
        pyprefix = prefix+'_p'+maxpystr
        maxnp = 0
        for j in [i for i in binaries if i.startswith(pyprefix)]:
            s = j.split('_n')[1]
            try:
                if float(s) > maxnp:
                    maxnp = float(s)
                    maxnpstr = s
            except ValueError:
                pass
        if maxnpstr is None:
            print('No NumPy version found')
    if maxpystr is None or maxnpstr is None:
        maxpystr, maxnpstr = '3.13', '2.2'
        print(f'Using default versions: Python ({maxpystr}), numpy ({maxnpstr})')
    return version, maxpystr, maxnpstr

def makeBuild(pyver,npver,name='build.sh'):
    '''Make the Linux/Mac 'build.sh' file for conda-build
    '''
    build_sh='''
echo '==================== running build.sh ===================='
logfile=/tmp/conda_G2build_out.log
#
echo starting Build.sh > $logfile 2>&1
cp $RECIPE_DIR/../gitstrap.py $PREFIX/
echo ls $PREFIX/ >> $logfile 2>&1
echo git= >> $logfile 2>&1
which git >> $logfile 2>&1
echo python= >> $logfile 2>&1
which python >> $logfile 2>&1
echo python $PREFIX/gitstrap.py --nocheck --noshortcut --noprogress --binary={npversion},{pyversion} --log=/tmp/gitstrap.log --branch={branch} >> $logfile 2>&1
python $PREFIX/gitstrap.py --nocheck --noshortcut --noprogress --binary={npversion},{pyversion} --log=/tmp/gitstrap.log --branch={branch} >> $logfile 2>&1
# rename the .git files so they get copied into the conda package
mv -v $PREFIX/GSAS-II/.git $PREFIX/GSAS-II/keep_git  >> $logfile 2>&1
mv -v $PREFIX/GSAS-II/.gitignore $PREFIX/GSAS-II/keep.gitignore  >> $logfile 2>&1
'''
    s = f'#!/bin/bash\n#written by {__file__}'
    s += build_sh.format(pyversion=pyver, npversion=npver,branch=branch)
    open(os.path.join(bldloc,name),'w').write(s)
    print('created',os.path.join(bldloc,name))

def makeBld(pyver,npver,name='bld.bat'):
    '''Make the Windows 'bld.bat' file for conda-build
    '''
    build_sh=r'''
REM  =========================================================================
REM  This gets run during build of a conda package to put all G2 files into
REM  the .conda file so they end up in the windows .exe
REM  =========================================================================
REM
 
rem set outloc=c:\tmp
set outloc=%PREFIX%
set logfile=%outloc%\constructor_bld.log
set gitlog=%outloc%\gitstrap_bld.log
if exist "%PREFIX%\GSAS-II" (
   exit 1
 )
echo copy %RECIPE_DIR%\..\gitstrap.py %PREFIX%\ >  %logfile%
     copy %RECIPE_DIR%\..\gitstrap.py %PREFIX%\ >> %logfile%
if errorlevel 1 exit 1

REM Install files now
echo python %PREFIX%\gitstrap.py --nocheck --noshortcut --noprogress --binary={npversion},{pyversion} --log=%gitlog% --branch={branch} >> %logfile%
     python %PREFIX%\gitstrap.py --nocheck --noshortcut --noprogress --binary={npversion},{pyversion} --log=%gitlog% --branch={branch} >> %logfile%
if errorlevel 1 exit 1

REM save the .git files so they get copied
cd %PREFIX%\GSAS-II
if errorlevel 1 exit 1
where tar >> %logfile%
REM Make a tar so we can put it back later
echo C:\Windows\System32\tar.exe czf git.tgz .git >> %logfile%
     C:\Windows\System32\tar.exe czf git.tgz .git >> %logfile%
if errorlevel 1 exit 1
dir /s
'''
    s = f'REM written by {__file__}'
    s += build_sh.format(pyversion=pyver, npversion=npver,branch=branch)
    open(os.path.join(bldloc,name),'w').write(s)
    print('created',os.path.join(bldloc,name))
    
def makeMetaYaml(Gver, pyver, npver, name='meta.yaml'):
    '''Make the meta.yaml file for conda-build (all platforms)
    '''
    meta_yaml = '''
# Used to builds a GSAS-II conda package that includes all GSAS-II files
# including binaries matched to versions of Python and NumPy
# this contains the packages that GSAS-II requires
package: 
  name: gsas2main
  version: "{Version}"

build:
  number: 0

about:
  home: https://advancedphotonsource.github.io/GSAS-II-tutorials

requirements:
  run:
    - python={pyversion}
    - numpy={npversion}
    - matplotlib
    - wxpython
    - pyopengl
    - scipy
    - git
    - gitpython
    - PyCifRW
    - conda
# useful packages, but not required packages are:
#    - pillow
#    - requests
#    - hdf5
#    - h5py
#    - imageio
#    - zarr
#    - xmltodict
#    - pybaselines
#    - seekpath
#    - pywin32                              [win]
'''
    s = f'#written by {__file__}'
    s += meta_yaml.format(pyversion=pyver, npversion=npver, Version=Gver)
    open(os.path.join(bldloc,name),'w').write(s)
    print('created',os.path.join(bldloc,name))

def makeConstructYaml(Gver, pyver, npver, name='construct.yaml'):
    '''Make the construct.yaml file for conda constructor (all platforms)
    '''
    construct_yaml='''
name: gsas2main
version: {Version}

channels:
  - https://conda.anaconda.org/conda-forge

conda_default_channels:
  - https://conda.anaconda.org/conda-forge

specs:
    - python={pyversion}
    - numpy={npversion}
    - matplotlib
    - wxpython
    - pyopengl
    - scipy
    - briantoby::gsas2main
    - git
    - gitpython
    - PyCifRW
    # following package are not required but are included anyway
    - pillow
    - conda
    - requests
    - hdf5
    - h5py
    - imageio
    - zarr
    - xmltodict
    - pybaselines
    - seekpath
    - pywin32                              [win]

post_install: g2postinstall.sh           [unix]
post_install: g2postinstall.bat           [win]

license_file: EULA.txt

welcome_image: gsas2-welcome.png
icon_image: gsas2.png

keep_pkgs: False
register_python_default: False
initialize_by_default: False
company: Argonne National Laboratory
write_condarc: True
'''
    s = f'#written by {__file__}'
    s += construct_yaml.format(pyversion=pyver, npversion=npver, Version=Gver)
    open(os.path.join(bldloc,name),'w').write(s)
    print('created',os.path.join(bldloc,name))

    
if __name__ == '__main__':
    vlist = getNewestVersions()
    if vlist is None: sys.exit(1)
    Gver, pyver, npver = vlist
    if sys.platform == "win32":
        makeBld(pyver,npver)
    else:
        makeBuild(pyver,npver)
    makeMetaYaml(Gver, pyver, npver)
    makeConstructYaml(Gver, pyver, npver)
