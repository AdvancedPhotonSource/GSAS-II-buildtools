hostid="Build on s11bmbcda (VM)"
WORKSPACE=/tmp/g2py3.11
if [ ! -e "$WORKSPACE" ]; then
    mkdir $WORKSPACE
    echo mkdir $WORKSPACE
fi
condaHome=/tmp/conda311
svn=`which svn`
miniforge=https://github.com/conda-forge/miniforge/releases/download/23.3.1-1/Mambaforge-23.3.1-1-Linux-x86_64.sh

install=True
install=False

dryrun=False
#dryrun=True
env=py311   # 2/9/24: py3.11.7, np 1.26.4, MPL 3.8.2, wx 4.2.1

compile=True
#compile=False

#build=True
#upload=True
upload=False

#========== Anaconda stuff
if [ "$install" = "True" ]
then
	rm -rf $condaHome
	if [ ! -e "/tmp/Miniconda3-latest.sh" ]; then
	    curl -L $miniforge -o /tmp/Miniconda3-latest.sh
	else
	    echo "skip miniconda download"
	fi
	if [ ! -d "$condaHome" ]; then   # this is not working at present
	    bash /tmp/Miniconda3-latest.sh -b -p $condaHome
	else
	    echo "skip miniconda install"
	fi
	#rm /tmp/Miniconda3-latest.sh
fi

echo source $condaHome/bin/activate
     source $condaHome/bin/activate
if [ "$dryrun" = "True" ]
then
    conda create --dry-run -n test python=3.11 wxpython numpy scipy matplotlib pyopengl pillow h5py imageio conda requests scons gfortran
    exit
fi

if [ "$install" = "True" ]
then
	conda create -y -n $env python=3.11 wxpython numpy scipy matplotlib pyopengl pillow h5py imageio conda requests scons gfortran #  anaconda-client constructor conda-build sphinx sphinx-rtd-theme git
fi

#set +x
echo source $condaHome/bin/activate $env
     source $condaHome/bin/activate $env

#==================================== Build of .so files ==================================
newdir="fail"
if [ "$compile" = "True" ]
then
  $svn co https://subversion.xray.aps.anl.gov/pyGSAS/trunk/fsource $WORKSPACE/GSASII/fsource
  ########################
  # start compile process
  ########################
  # START debug stuff
  #set -x
  which python
  gfortran -v
  #   which ld
  #export PATH="/usr/local/bin:$PATH"  # make sure system gfortran is used
  rm -rf GSASII/AllBinaries
  cd $WORKSPACE/GSASII/fsource

  scons -c # cleanup old
  set +x
  scons install=T
  # document build
  #=# find the build dir name; add info to Build notes
  newdir=`cd $WORKSPACE/GSASII/AllBinaries/; ls -d linux*`
  echo $newdir
  #set -x
  cp $WORKSPACE/GSASII/bin/Build.notes.txt $WORKSPACE/GSASII/AllBinaries/$newdir/
  SVN_REVISION="`svn info https://subversion.xray.aps.anl.gov/pyGSAS/trunk/fsource | grep Revision`"
  HOST="`hostname`"
  echo "Built on $hostid from $SVN_REVISION" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  sw_vers >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  conda list -f python | tail -1 >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  conda list -f numpy | tail -1 >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  #conda list -f gfortran_linux-64 | tail -1 >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  echo "Using `which gfortran`, info follows" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  gfortran -v 2>> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  ldd $WORKSPACE/GSASII/AllBinaries/$newdir/* >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
fi

if [ "$compile" = "True" ]
then
    if [ ! -d $WORKSPACE/GSASII/AllBinaries/$newdir ]; then   # this is not working at present
	echo $WORKSPACE/GSASII/AllBinaries/$newdir not found
	exit
    fi
    cd $WORKSPACE/GSASII/AllBinaries/$newdir
    cp $CONDA_PREFIX/lib/libquadmath.so.0 .
    cp $CONDA_PREFIX/lib/libgfortran.so.5 .
    cp $CONDA_PREFIX/lib/libgcc_s.so.1 .
    tar cvzf /tmp/$newdir.tgz *
    echo "Add /tmp/$newdir.tgz to binary release in https://github.com/GSASII/binarytest/releases"
    exit
fi
