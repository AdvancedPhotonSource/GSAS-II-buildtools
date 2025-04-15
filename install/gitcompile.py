#!/usr/bin/env python
# Installs GSAS-II from GitHub, compiles it with meson and
# creates platform-specific shortcuts.
# Works for Mac & Linux & Windows
from __future__ import division, print_function
import os, stat, sys, platform, subprocess, datetime, shutil, glob

version = "gitcompile.py from April 2025"
g2URL = "https://github.com/AdvancedPhotonSource/GSAS-II.git"
scriptpath = os.path.dirname(os.path.abspath(os.path.expanduser(__file__)))
# Python packages needed to compile
# in addition git, gfortran, gcc or clang are needed, which can be installed via conda or not
CompilePackages = ['cython', 'numpy']
# packages that GSAS-II needs to run
RunReqPackages = ['git','numpy','matplotlib','wx','OpenGL','scipy','CifFile', 'conda']
# packages that are optional but should be present for GSAS-II
RunOptPackages = ['PIL','requests','h5py','imageio','zarr','xmltodict','pybaselines','seekpath']
# where the import name is not the package name, translate with:
pkgnames = {'wx':'wxpython', 'OpenGL':'pyopengl','CifFile':'PyCifRW','PIL':'pillow',
                'git':'gitpython'}
# command-line tools
tools = ['meson', 'gfortran', 'gcc', 'git']

if sys.platform.startswith('win'): RunOptPackages += 'pywin32'
# PackagePackages = 'constructor','conda','conda-build','anaconda-client'

# This installs GSAS-II files in a directory called GSAS-II which
#will be placed as a subdirectory of the location where this script
#resides, unless overridden by the --loc=path argument
path2repo = os.path.join(scriptpath,'GSAS-II')
# The GSAS-II Python files go into a subdirectory of path2repo
# (default GSAS-II/GSASII) in variable path2GSAS2

# command line argument variables
reset = False              # True: any locally-made changes to GSAS-II
                           # files are reverted to the distribution
                           # versions; the files are updated to the
                           # current version (Reset mode). Default is False.
                           # Use --reset to invoke Reset mode.
                           # Note that skipShortcut is also set when --reset
                           # is used

skipChecks = False         # False: checks are made that required Python
                           # packages are present.
                           # Use --nocheck to install without checks
                           
skipCompile = False        # True: compilation (with meson) is skipped
                           # Use --nocompile to prevent compilation
                           
skipShortcut = False       # if False, shortcuts are created after installing
                           # GSAS-II files.
                           # Use --noshortcut to run script without creating
                           # shortcuts after installation

skipDownload = False       # if False, download GSAS-II files are downloaded
                           # Use --nodownload to run script without downloading

WXerror = False            # if False error messages are shown in terminal
                           # window
                           # use --wxerrors to have error messages shown in
                           # a GUI window
                           
help = False               # use --help to show short info on script use
                           #--> True: -help

depth=500                  # determines the number of past versions of
                           # GSAS-II to install locally. The larger this
                           # number, the more local storage space needed.
                           # 100 or even 500 does not increase this by very
                           # much.
                           # Use --ver to set this.

allBinaries = False        # False: the binaries for only one version of
                           # Python/numpy are installed.
                           # Use --server to set to True, where all binary
                           # files in the GitHub release are installed.
                           # Used for installation to a GSAS-II server.

ProgressCnt = True         # include a progress counter on clone

logfile=None               # name of log file used by this script. If
                           # None (default), this is set to gitcompile.log
                           # in the parent directory of where GSAS-II is
                           # installed. Override this with --log

branch=None                # name of git branch to install. None (default)
                           # causes main to be installed.
                           # to be used

# option not yet implemented (not sure yet how to handle proxy settings)
                           
skipProxy = False          # False: the script prompts for for proxy info
                           # Use --noproxy to avoid this
                           
for a in sys.argv[1:]:
    if '-r' in a.lower():
        reset = True
        skipShortcut = True
    elif '-nop' in a.lower():
        ProgressCnt = False
    elif '-nos' in a.lower():
        skipShortcut = True
    elif '-noch' in a.lower():
        skipChecks = True
    elif '-noco' in a.lower():
        skipCompile = True
    elif '-nod' in a.lower():
        skipDownload = True
    elif '-w' in a.lower():
        WXerror = True
    elif '-loc' in a.lower():
        bad = False
        try:
            _,pth = a.split('=')
            pth = os.path.abspath(os.path.expanduser(pth))
            parent = os.path.dirname(pth)
            if not os.path.exists(parent):
                print(f'\nError: directory {parent!r} not found.')
                bad = True
            path2repo = pth
        except:
            bad = True
        if bad:
            print(f'Argument {a} is invalid.')
            help = True
            break
    elif '-log' in a.lower():
        bad = False
        try:
            _,pth = a.split('=')
            pth = os.path.abspath(os.path.expanduser(pth))
            parent = os.path.dirname(pth)
            if not os.path.exists(parent):
                print(f'\nError: directory {parent!r} not found.')
                bad = True
            logfile = pth
        except:
            bad = True
        if bad:
            print(f'Argument {a} is invalid.')
            help = True
            break
    elif '-v' in a.lower():
        bad = False
        try:
            _,ver = a.split('=')
            depth = int(ver)
            if depth < 1:
                bad = True
        except:
            bad = True
        if bad:
            print(f'Argument {a} is invalid.')
            help = True
            break
    elif '-b' in a.lower():
        bad = False
        _,branch = a.split('=')
    # elif '-bi' in a.lower():
    #     bad = False
    #     try:
    #         _,ver = a.split('=')
    #         vers = ver.split(',')
    #         if len(vers) == 1:
    #             npVersion = vers[0].replace('(','').replace(')','')
    #             # remove 'patch' version # if present
    #             npVersion = npVersion.rsplit('.',npVersion.count('.')-1)[0] 
    #         elif len(vers) == 2:
    #             npVersion = vers[0].replace('(','')
    #             pyVersion = vers[1].replace(')','')
    #             npVersion = npVersion.rsplit('.',npVersion.count('.')-1)[0]
    #             pyVersion = pyVersion.rsplit('.',pyVersion.count('.')-1)[0] 
    #         else:
    #             bad = False
    #         skipChecks = True
    #     except:
    #         bad = True
    #     if bad:
    #         print(f'Argument {a} is invalid.')
    #         help = True
    #         break
    # elif '-s' in a.lower():
    #     allBinaries = True
    #     skipChecks = True
    elif '-h' in a.lower():
        help = True
    else:
        print(f'Argument {a} is invalid.')
        help = True
        
    #if '-noproxy' in a.lower():
    #    skipProxy = True

if help:
    print(f'''
  gitcompile.py options:

    --nocheck     do not check if required Python packages are present

    --nocompile   do not attempt to compile binaries

    --noshortcut  skip post-install steps, such as creating run shortcuts

    --nodownload  skips downloading or updating GSAS-II from the web, 
                  GSAS-II files assumed to be previously installed 

    --wxerror     errors are shown in a GUI (wx) window

    --loc=path    install to location path rather than a subdirectory named 
                  GSAS-II located in the directory where this script is 
                  found ({scriptpath}). 
                  The path will be created if it does not exist, but the 
                  parent of the path must exist.

    --log=file    Specifies the name of the file to use for a log of output 
                  from this script. Specify a this with a full path. The 
                  default is gitcompile.log in the parent directory of where 
                  GSAS-II will be installed.

    --ver=depth   overrides the default number of old GSAS-II versions
                  that will be installed (from 500). Changes the space 
                  needed to install GSAS-II.

    --noprogress  omit the progress counter when downloading GSAS-II files 

    --branch=git-branch  Causes the named branch to be installed rather
                  than main

    --reset       Removes any locally-changed GSAS-II files and updates to 
                  the latest GSAS-II version. Useful when GSAS-II will not 
                  start. --noshortcut is set when --reset is used. 

    --help        shows this message

Note that options may be abbreviated to the minumum number of letters 
needed for uniqueness and one dash works the same as two 
(e.g. -b is equivalent to --branch, but -noch is needed for --nocheck).
''')
    sys.exit()

    # not implemented, yet
    # --noproxy     do not ask for proxy information
    # --allbin      load all binary versions (same as --server)
    
# The GSAS-II Python files go into a subdirectory of path2repo
# (default GSAS-II/GSASII) 
path2GSAS2 = os.path.join(path2repo,'GSASII')

now = str(datetime.datetime.now())
msg = f'\nBootstrapping GSAS-II into {path2repo}\nat {now}\nfrom {g2URL}'
if branch:
    msg += f', branch {branch}'
else:
    msg += ', branch main'
msg += '\n'
msg += f'\nscript:     {version}'
msg += f"\nPython:     {sys.version.split()[0]}"
try:
    import numpy as np
    msg += f"\nnumpy:      {np.__version__}"
except:
    pass
print(msg)
if not logfile:
    logfile = os.path.normpath(os.path.join(path2repo,'..','gitcompile.log'))
print(f'log in {logfile}')
def logmsg(msg):
    fp = open(logfile,'a')
    fp.write(msg+'\n')
    fp.close()
logmsg(msg)
        
################################################################################
################################################################################

def BailOut(msg):
    '''Exit with an error message. Use a GUI to show the error when
    WXerror is True
    '''
    logmsg(f'Installation failed with this message:\n{msg}\n')
    if WXerror:
        print("\nError during bootstrap:")
        print(msg)
        try: 
            import wx
            app = wx.App()
            dlg = wx.MessageDialog(None,msg,'GSAS-II installation error', 
                wx.OK | wx.ICON_ERROR | wx.STAY_ON_TOP)
            #dlg.Raise()
            dlg.ShowModal()
            dlg.Destroy()
        except:
            print('Note: wx GUI creation failed')
    else:
        print("\nError during bootstrap: ",file=sys.stderr)
        for line in msg.split('\n'):
            print('  ',line,file=sys.stderr)
        print("\nRerun this script using command:")
        print(f"     {os.path.abspath(sys.executable)}"+
              f" {os.path.abspath(os.path.expanduser(__file__))}"+
              f" {' '.join(sys.argv[1:])}",
                  file=sys.stderr)
    sys.exit()

def gitInstallGSASII(repo_URL,repo_path,depth=500,forceupdate=False,verbose=True,branch=None):
    '''Install GSAS-II from git to a location. If the directory does 
    not exist it will be created. If the directory exists, and has not 
    been used for git before, it must be empty. If not a ValueError Exception
    is raised.

    If a .git repostory is found at the location, the GSAS-II files 
    will be updated to the latest version in the main repository, unless 
    locally made changes have been made to those files. If changes have 
    been made then `forceupdate` must be set as True for the update to 
    be applied, otherwise a UserWarning Exception is generated. 

    :param str repo_URL: location of the GSAS-II repository on GitHub (URL)
    :param str repo_path: location where GSAS-II will be or has been installed
    :param int depth: number of old versions to install (default is 500). 
      Set this to None to install them all (not recommended as the download 
      takes a while and the space requirement goes up by an order of 
      magnitude). 
    :param bool forceupdate: If the GSAS-II files have been modified 
      locally and this is True, then an update will be attempted anyway. 
      (Default is False.)
    :param bool verbose: When True (default) lots of messages are printed. 
      Otherwise this routine will not print anything. 
    :param str branch: When None (default), this is set as main. Otherwise this
      specifies the name of the branch to be installed.

    :returns: False if a new installation is made and True if an update
      to an existing installation has been made. Anything else
      will result in an Exception being raised. 
    '''
    class gitProgress(git.RemoteProgress):
        def update(self, op_code, cur_count, max_count=None, message=''):
            print(f"Progress {int(0.5 + 100*cur_count / (max_count or 100.0))}%  ",end='\r')
            sys.stdout.flush()

    if os.path.exists(repo_path):  # does the directory exist?
        if os.path.exists(os.path.join(repo_path,'.git')): # yes and has git
            # assume GSAS-II, update 
            if verbose: print(f'Software already uploaded at {repo_path}.'
                               ' Will attempt update.')
            g2repo = git.Repo(repo_path)
            if g2repo.is_dirty():
                msg = f'directory {repo_path} has local modifications'
                if verbose:
                    logmsg(msg)
                    print(msg)
                if not forceupdate: raise UserWarning(msg)            
            g2repo.remotes.origin.pull(f'--depth={depth}')
            return True
        elif os.listdir(repo_path):
            msg = f'directory {repo_path} is not empty and is not used by git'
            logmsg(msg)
            raise ValueError(msg)
    else:
        msg = f'creating directory {repo_path}'
        if verbose:
            logmsg(msg)
            print(msg)
    # empty directory or one to be created, use git to install GSAS-II
    progress = None
    if verbose:
        msg = f'Cloning GSAS-II to {repo_path} from {repo_URL}.'
        if branch:
            msg += f' Using branch={branch}.'
        else:
            msg += ' Using branch=main.'
        print(msg)
        logmsg(msg)
        if ProgressCnt: progress = gitProgress()
    if not branch:
        branch = 'main'
    git.Repo.clone_from(repo_URL,repo_path,depth=depth,progress=progress,
                            branch=branch)
    if verbose:
        logmsg('clone done')
        print('\nclone done')
    return False

def gitResetGSASII(repo_path,verbose=True):
    '''Reset an existing GSAS-II installation to the latest version
    of GSAS-II, wiping out any locally made changes to those files.
    Use this if GSAS-II files have been left in a situation where 
    an error prevents GSAS-II from starting or updating.

    :param str repo_path: location where GSAS-II has been installed
    :param bool verbose: When True (default) lots of messages are printed. 
      Otherwise this routine will not print anything. 
    :returns: True if the repository is found and has been reset, False
      if no repository is at that location.
    '''
    if os.path.exists(os.path.join(repo_path,'.git')): 
        git.Repo(repo_path).git.reset('--hard','origin/main')
        return True
    else:
        if verbose: print(f'Warning: Repository {repo_path} not found')
        return False

################################################################################
################################################################################

print(70*'*')
# check that required packages/tools are present
required = []
recommended = []
if not skipChecks:
    print('Checking python packages...', end='')
    for pkglist in CompilePackages,RunReqPackages,RunOptPackages: # PackagePackages
        for pkg in pkglist:
            try:
                exec('import '+pkg)
            except:
                pkg = pkgnames.get(pkg,pkg)
                if 'h5py' in pkglist:
                    recommended.append(pkg)
                else:
                    required.append(pkg)
if recommended:
    msg = "\n\nThis installation of Python does not have all packages needed for full GSAS-II\n"
    msg += "functionality. It is missing the following package(s):\n"
    msg += "\t" + ', '.join(recommended)
    msg += "\nSince GSAS-II can run without them, installation will continue, but you\n"
    msg += "are recommended to install these package(s).\n"
    print(msg)
if required:
    if not recommended: print(' failed')
    msg = "Sorry, this installation of Python cannot be used to run GSAS-II.\n"
    msg += "It is missing the following package(s):\n"
    msg += "\t" + ', '.join(required)
    msg += "\nPlease install these package(s) and try running gitcompile.py again."
    BailOut(msg)
elif not skipChecks and not recommended:
    print(' passed\n')
elif skipChecks:
    print('no check of Python packages\n')

missing = []
for t in tools:
    if not shutil.which(t):
        missing.append(t)
if missing:
    print('The following commands are not installed: ',', '.join(missing))
    if not skipChecks:
        BailOut('Please install these tool(s), for example using conda')

    
if not skipDownload:
    try:
        import git
    except:
        msg = "Sorry, this script cannot be run without the git package and\n"
        msg += "without git installed.\n"
        msg += "\nPlease install these and try running gitcompile.py again."
        BailOut(msg)

if reset:
    if gitResetGSASII(path2repo):
        print('git reset performed')
    else:
        print('reset failed')

if not skipDownload:
    try:
        gitInstallGSASII(g2URL,path2repo,depth=depth,branch=branch) # forceupdate=False
    except UserWarning:
        print('\n***Unable to update due to changes that have been made locally to GSAS-II files')
        print('If an update must be done from inside this script, use --reset')

    # GSAS-II files now present, start on binary installation
    sys.path.insert(0,path2GSAS2)
    try:
        import GSASIIpath
    except:
        print('import of GSASIIpath failed, why?')
        sys.exit()


# do compile of binaries
if not skipCompile:
    installLoc = os.path.join(path2repo,'GSASII-bin')
    print ('Binary install location', installLoc)
    buildLoc = os.path.abspath(os.path.join('.','build'))
    print ('Binary build location', buildLoc)
    sourceLoc = os.path.abspath(os.path.join(path2GSAS2,'..'))
    print ('Source code location', sourceLoc)
    subprocess.run(["meson","setup",buildLoc],cwd=sourceLoc)
    subprocess.run(["meson","compile","-C",buildLoc])
    if sys.platform.startswith('win'):
        exe = '.exe'
        pyd = '*.pyd'
    else:
        exe = ''
        pyd = '*.so'
    exeList = []
    #exeList += glob.glob(os.path.join(buildLoc,'sources','LATTIC'+exe))
    #exeList += glob.glob(os.path.join(buildLoc,'sources','convcell'+exe))
    copyList = exeList[:]
    copyList += glob.glob(os.path.join(buildLoc,'sources',pyd))
    copyList += glob.glob(os.path.join(buildLoc,'sources','*',pyd))
    copyList += glob.glob(os.path.join(buildLoc,'sources','GSASIIversion.txt'))
    if not os.path.exists(installLoc): os.mkdir(installLoc)
    for f in copyList:
        shutil.copyfile(f,os.path.join(installLoc,os.path.split(f)[1]))
        #shutil.copy(f,installLoc)
    # put +x back on executables
    #for f in exeList:
    #    print('chmod',os.path.split(f)[1],0o555)
    #    os.chmod(os.path.join(installLoc,os.path.split(f)[1]),0o555)
    with open(os.path.join(installLoc,'Build.notes.txt'),'w') as fp:
        fp.write(f'built locally with Python {platform.python_version()}\n')
        import numpy
        fp.write(f'numpy version {numpy.__version__}\n')
        fp.write('gfortran info: ')
        fp.write(subprocess.run(["gfortran","-v"],capture_output=True).stderr.decode("utf-8"))
    msg = f'Binaries created  in {installLoc} using meson\n'
    print(msg)
    logmsg(msg)
    shutil.rmtree(buildLoc)
    print ('Deleted Binary build location:', buildLoc)
#===========================================================================
# Create all the .pyc files here
logmsg('Start byte-compile')
print(f'Byte-compiling all .py files in {path2GSAS2!r}... ',end='')
import compileall
compileall.compile_dir(path2GSAS2,quiet=True)
print('done')
logmsg('byte-compile done')
#===========================================================================
#===========================================================================
# do platform-dependent stuff
#===========================================================================
if skipShortcut: sys.exit()
logmsg('start system-specific install')
for k,s in {'win':"makeBat.py", 'darwin':"makeMacApp.py",
                'linux':"makeLinux.py"}.items():
    if sys.platform.startswith(k):
        script = os.path.join(path2GSAS2,'install',s)
        if not os.path.exists(script):
            logmsg(f'Platform-specific script {script!r} not found')
            script = ''
        break
else:
    print(f'Unknown platform {sys.platform}')

# G2script is not used here, but will be used in makeLinux.py (& makeBat.py?)
G2script = os.path.join(path2GSAS2,'GSASII.py')
if not os.path.exists(G2script): # B.B. GSASII.py will be replaced by G2.py
    G2script = os.path.join(path2GSAS2,'G2.py')

# on a Mac, make an applescript
if script and sys.platform.startswith('darwin'):
    logmsg(f'running {script}')
    out = subprocess.run([sys.executable,script],cwd=path2GSAS2)
# On linux, make a desktop icon & on windows make a batch file
# each has hard-coded paths to Python and GSAS-II
elif script:
    sys.argv = [script]
    logmsg(u'running '+sys.argv[0])
    with open(sys.argv[0]) as source_file:
        exec(source_file.read())

logmsg('system-specific install done')
#===========================================================================
#===========================================================================
# test if the binary files load correctly
# At present this is not in use.
#===========================================================================
GSASIItested = False
script = """  
# commands that test each module can at least be loaded & run something in pyspg
try:
    import GSASIIpath
    GSASIIpath.SetBinaryPath(loadBinary=False)
    import pyspg
    import histogram2d
    import polymask
    import pypowder
    import pytexture
    pyspg.sgforpy('P -1')
    print('==OK==')
except Exception as err:
    print(err)
"""
if False and not skipDownload and not skipChecks:
    p = subprocess.Popen([sys.executable,'-c',script],stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                         cwd=path2GSAS2)
    res,err = MakeByte2str(p.communicate())
    if '==OK==' not in str(res) or p.returncode != 0:
        #print('\n'+75*'=')
        msg = 'Failed when testing the GSAS-II compiled files. GSAS-II will not run'
        msg += ' without correcting this.\n\nError message:\n'
        if res: 
            msg += res
            msg += '\n'
        if err:
            msg += err
        #print('\nAttempting to open a web page on compiling GSAS-II...')
        msg += '\n\nPlease see web page\nhttps://subversion.xray.aps.anl.gov/trac/pyGSAS/wiki/CompileGSASII if you wish to compile for yourself (usually not needed for windows and Mac, but sometimes required for Linux.)'
        BailOut(msg)
        #import webbrowser
        #webbrowser.open_new('https://subversion.xray.aps.anl.gov/trac/pyGSAS/wiki/CompileGSASII')
        #print(75*'=')
    else:
        print('Successfully tested compiled routines')
        GSASIItested = True    
#===========================================================================
#===========================================================================
logmsg(f'Installation completed {datetime.datetime.now()}\n')
