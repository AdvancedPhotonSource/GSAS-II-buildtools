#=======================================================================
# this creates the gsas2full self-installer for Linux using a git
# repository. 
#
# download this file with 
# (cd /tmp; curl -L -O https://github.com/AdvancedPhotonSource/GSAS-II-buildtools/raw/main/localbuild/G2full_Linux64.sh)
#=======================================================================
WORKSPACE=/tmp
condaHome=/tmp/conda311
builds=~/build  # this must match what is in the g2full/construct.yaml file

#gitInstallRepo=git@github.com:AdvancedPhotonSource/GSAS-II-buildtools.git
#gitCodeRepo=git@github.com:AdvancedPhotonSource/GSAS-II.git
# some VMs can't use ssh, but can use https
gitInstallRepo=https://github.com/AdvancedPhotonSource/GSAS-II-buildtools.git
gitCodeRepo=https://github.com/AdvancedPhotonSource/GSAS-II.git

pyver=3.11
numpyver=1.26

packages="python=$pyver wxpython numpy=$numpyver scipy matplotlib pyopengl conda anaconda-client constructor conda-build git gitpython requests pillow h5py imageio scons"

env=bldpy311     # py 3.11.8 & np 1.26.4
miniforge=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge-Linux-x86_64.sh

install=True
#install=False

dryrun=False
#dryrun=True

gitinstall=True

#build=False
build=True

upload=False

#========== conda stuff
if [ "$install" = "True" ]
then
    rm -rf $condaHome
    if [ ! -e "/tmp/Miniforge-latest.sh" ]; then
	echo Downloading 
	curl -L $miniforge -o /tmp/Miniforge-latest.sh
    else
	echo "skipping miniconda download"
    fi
    if [ ! -d "$condaHome" ]; then
	echo creating conda installation 
	bash /tmp/Miniforge-latest.sh -b -p $condaHome
    else
	echo "skip miniconda install"
    fi
    #rm /tmp/Miniforge-latest.sh
fi

echo source $condaHome/bin/activate
     source $condaHome/bin/activate

if [ "$dryrun" = "True" ]
then
    conda create --dry-run -n test-env $packages
    exit
fi

if [ "$install" = "True" ]
then
	conda create -y -n $env $packages
fi

set +x
echo source $condaHome/bin/activate $env
     source $condaHome/bin/activate $env

if [ "$install" = "True" ]
then
    # create a workaround environment to avoid the buggy newer constructor versions
    conda create --name workaround --clone $env
    source $condaHome/bin/activate workaround
    conda install -y constructor=3.3
    source $condaHome/bin/activate $env
fi

#=========================== Build of g2complete package ==================================
#
#=============================
# Use commands below to build
#=============================
#if [ "$build" = "True" ]
if [ "$gitinstall" = "True" ]
then
    set -x
    # get the build routines so they can be run
    rm -rf $WORKSPACE/GSAS2-build
    mkdir $WORKSPACE/GSAS2-build
    git clone $gitInstallRepo $WORKSPACE/GSAS2-build --depth 1
    # get the GSAS-II code to get the latest version number etc.
    rm -rf $WORKSPACE/GSAS2-code
    mkdir $WORKSPACE/GSAS2-code
    git clone $gitCodeRepo $WORKSPACE/GSAS2-code --depth 50
fi

if [ "$build" = "True" ]
then    
    echo $WORKSPACE/GSAS2-build/install
    cd   $WORKSPACE/GSAS2-build/install
    echo python `pwd`/setgitversion.py $WORKSPACE/GSAS2-code
    python setgitversion.py $WORKSPACE/GSAS2-code

    rm -rf $builds
    mkdir -p $builds
    set +x
    echo conda build g2complete --output-folder $builds --numpy $numpyver
         conda build g2complete --output-folder $builds --numpy $numpyver
    set -x
    #
    #=========================== Build/upload of g2full installer =============================
    #
    source $condaHome/bin/activate workaround
    # Build the self-installer
    rm -f *.sh
    constructor g2full
    # March 2024: mamba solver has a bug, fixed in new version TBA
    # but not in 3.7.0, following command is a work-around
    #CONDA_SOLVER=classic constructor g2full
    set -x
    echo `pwd`
    ls -l *.sh
    mv -v *.sh $WORKSPACE   # put into $WORKSPACE
    echo Remember to copy $WORKSPACE/*.sh to GitHub Releases in AdvancedPhotonSource/GSAS-II-buildtools
    rm -rf $builds
	#ls -l *.*
fi

exit

# if [ "$upload" = "True" ]
# then
# 	echo upload build
# 	# copy to "Latest" and upload
# 	#cp gsas2full-*-MacOSX-x86_64.sh gsas2full-Latest-MacOSX-x86_64.sh
# 	# copy to https://subversion.xray.aps.anl.gov/admin_pyGSAS/downloads/gsas2full-*-MacOSX-x86_64.sh
# 	scp ../gsas2full-*.sh svnpgsas@s11bmbcda.xray.aps.anl.gov:/home/joule/SVN/subversion/pyGSAS/downloads/
# 	#echo files found at https://subversion.xray.aps.anl.gov/admin_pyGSAS/downloads/gsas2full-*-MacOSX-x86_64.sh
# 	#ssh svnpgsas@s11bmbcda.xray.aps.anl.gov ls -lt /home/joule/SVN/subversion/pyGSAS/downloads/gsas2full-*-MacOSX-*.sh
# fi
