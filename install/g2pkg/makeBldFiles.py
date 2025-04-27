# this creates the meta.yml file needed to build the gsas2pkg conda package

import os
import sys
import platform
import git

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

def getGitBinaryReleases():
    '''Retrieves the binaries and download urls of the latest release

    Based on similar routine in GSASIIpath

    :returns: a list of GSAS-II binary distributions found in the newest 
      release in a GitHub repository. The repo location is defined in global 
      `G2binURL`.
    '''
    # Get first page of releases
    try:
        import requests
    except:
        print('Unable to install binaries in getGitBinaryReleases():\n requests module not available')
        return
    releases = []
    tries = 0
    while tries < 5: # this has been known to fail, so retry
        tries += 1
        releases = requests.get(
            url=f"{G2binURL}/releases", 
            headers=BASE_HEADER
        ).json()
        try:        
            # Get assets of latest release
            assets = requests.get(
                url=f"{G2binURL}/releases/{releases[-1]['id']}/assets",
                headers=BASE_HEADER
                ).json()

            versions = []
            #URLs = []
            count = 0
            for asset in assets:
                if asset['name'].endswith('.tgz'):
                    versions.append(asset['name'][:-4]) # Remove .tgz tail
                    #URLs.append(asset['browser_download_url'])
                    count += 1
        except:
            print('Attempt to list GSAS-II binary releases failed, sleeping for 100 sec and then retrying')
            import time
            time.sleep(100)  # this does not seem to help when GitHub is not letting the queries through
            continue
        return versions

def getNewestVersions():
    '''get the latest Python & numpy versions with supplied binaries, 
    as well as the latest numerical tag name used in the GSAS-II repo

    :returns: version, maxpystr, maxnpstr or None, where 
      * version: GSAS-II numerical version number
      * maxpystr: latest supported Python version (x.y)
      * maxnpstr: latest supported numpy version (x.y)
      * dotversion: GSAS-II major/minor/mini version number
    '''
    
    binaries = getGitBinaryReleases()
    if binaries is None:
        print('No binaries found!')
        binaries = []
    prefix = GetBinaryPrefix()

    # these command gets the latest numerical tag in most recent entries in the branch
    import os,tempfile,shutil
    tpath = os.path.join(tempfile.gettempdir(),'git-tmp')
    r = git.Repo.clone_from(G2url,branch=branch,depth=500,to_path=tpath)
    tags = [tag.name for tag in r.tags] # get all the tags
    r.close() # clean up
    try:
        shutil.rmtree(tpath)
    except:  # since a tempfile, will get cleaned up eventually anyway...
        pass
    version = sorted([i for i in tags if i.isdecimal()],key=int)[-1]
    dotversion = sorted([i for i in tags if i.startswith('v')])[-1]

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
    return version, maxpystr, maxnpstr, dotversion

def makeMetaYaml(Gver, pyver, npver, dotVer, name='meta.yaml'):
    '''Make the meta.yaml file for conda-build (all platforms)
    '''
    meta_yaml = '''
# note that this has pinned packages to match pre-build binaries

package: 
  name: gsas2pkg
  version: "{Version}"

about:
  home: https://advancedphotonsource.github.io/GSAS-II-tutorials

build:
  number: 0
#  noarch: python # can't use this, alas. See
#  https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html#architecture-independent-packages

requirements:
  run:
    - python={pyversion}
    - numpy={npversion}
    - conda
    - scipy
    - matplotlib
    - pyopengl
    - requests
    - wxpython
    - PyCifRW
    - git
    - gitpython
    - pywin32                              [win]
    # recommended packages
    - pillow        # kind of big, perhaps make this optional?
    - hdf5
    - h5py
    - imageio
    - zarr
    - pybaselines
    - xmltodict
    - seekpath
'''
    s = f'#written by {__file__}'
    s += meta_yaml.format(pyversion=pyver, npversion=npver, Version=dotVer[1:])
    open(os.path.join(bldloc,name),'w').write(s)
    print('created',os.path.join(bldloc,name),
              f"\nGSAS-II Version={Gver},{dotVer}, python={pyver}, numpy={npver}")

if __name__ == '__main__':
    vlist = getNewestVersions()
    if vlist is None: sys.exit(1)
    Gver, pyver, npver, dotVer = vlist
    makeMetaYaml(Gver, pyver, npver, dotVer)
