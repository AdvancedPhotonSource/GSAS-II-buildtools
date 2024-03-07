WORKSPACE=/tmp/g2py3.11
if [ ! -e "$WORKSPACE" ]; then
    mkdir $WORKSPACE
    echo mkdir $WORKSPACE
fi
condaHome=/tmp/conda311
svn=/Users/toby/conda37/bin/svn
miniforge=https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-MacOSX-x86_64.sh
FLIBloc=/usr/local/gfortran/lib 

install=True
install=False

dryrun=False
#dryrun=True
env=py311   # 2/7/24: py3.11.1, np 1.26.4, MPL 3.8.2, wx 4.2.1

compile=True
#compile=False

upload=True
#upload=False

#========== conda stuff
if [ "$install" = "True" ]
then
	if [ ! -e "/tmp/Miniconda3-latest.sh" ]; then
	    curl -L $miniforge -o /tmp/Miniconda3-latest.sh
	else
	    echo "skip miniconda download"
	fi
	if [ ! -d "$condaHome" ]; then
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
    conda create --dry-run -n test python=3.11 wxpython numpy scipy matplotlib pyopengl pillow h5py imageio conda requests scons
    exit
fi

if [ "$install" = "True" ]
then
	conda create -y -n $env python=3.11 wxpython numpy scipy matplotlib pyopengl conda scons # h5py imageio requests pillow anaconda-client constructor conda-build sphinx sphinx-rtd-theme git
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
  export FORTpath="/usr/local/bin"
  which $FORTpath/gfortran
  #export FLIBloc="/usr/local/opt/gcc/lib/gcc/current/"
  rm -rf GSASII/AllBinaries
  cd $WORKSPACE/GSASII/fsource

  scons -c # cleanup old
#  set +x
  scons install=T FORTpath=$FORTpath LIBGFORTRAN=T LIBGCC=T # LIBGFORTRAN seems OK on OSX

  #=# find the build dir name; add info to Build notes
  newdir=`cd ../AllBinaries/; ls -d mac*`
  echo $newdir

  # fix dylib naming
  python macRelink.py ../AllBinaries/$newdir
  
  # document build
  #set -x
  cp ../bin/Build.notes.txt ../AllBinaries/$newdir/
  SVN_REVISION="`svn info https://subversion.xray.aps.anl.gov/pyGSAS/trunk/fsource | grep Revision`"
  HOST="`hostname`"
  echo "Built on $HOST from G2 version $SVN_REVISION" >> ../AllBinaries/$newdir/Build.notes.txt
  sw_vers >> ../AllBinaries/$newdir/Build.notes.txt
  conda list -f python | tail -1 >> ../AllBinaries/$newdir/Build.notes.txt
  conda list -f numpy | tail -1 >> ../AllBinaries/$newdir/Build.notes.txt
  #conda list -f gfortran_linux-64 | tail -1 >> ../AllBinaries/$newdir/Build.notes.txt
  echo "Using $FORTpath/gfortran, info follows" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  $FORTpath/gfortran -v 2>> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  echo "*** Dependencies" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  otool -L $WORKSPACE/GSASII/AllBinaries/$newdir/* >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
   cp $FLIBloc/libquadmath.0.dylib $WORKSPACE/GSASII/AllBinaries/$newdir/
fi

if [ "$upload" = "True" ]
then
    if [ ! -d $WORKSPACE/GSASII/AllBinaries/$newdir ]; then   # this is not working at present
	echo $WORKSPACE/GSASII/AllBinaries/$newdir not found
	exit
    fi
    cd $WORKSPACE/GSASII/AllBinaries/$newdir
    tar cvzf /tmp/$newdir.tgz *
    echo "Add /tmp/$newdir.tgz to binary release in https://github.com/GSASII/binarytest/releases"
    exit
fi


# if [[ "$compile" = "True" ] && [ "$upload" = "True" ]]
# then
# #upload=True

#   #================
#   # Upload binaries
#   #================
#   $svn co -q https://subversion.xray.aps.anl.gov/pyGSAS/Binaries $WORKSPACE/Binaries
# fi


# if [[ ("$compile" = "True") && (! -d $WORKSPACE/Binaries/$newdir) ]]
# then
#     mkdir $WORKSPACE/Binaries/$newdir
#     $svn add $WORKSPACE/Binaries/$newdir
# fi

# if [ "$compile" = "True" ]
# then
#   python $WORKSPACE/Binaries/macRelink.py ../AllBinaries/$newdir
#   cp ../AllBinaries/$newdir/* $WORKSPACE/Binaries/$newdir
#   #cp $CONDA_PREFIX/lib/libgcc_s.1.dylib $WORKSPACE/Binaries/$newdir/
#   cp $FLIBloc/libquadmath.0.dylib $WORKSPACE/Binaries/$newdir/
#   echo Uploading
#   $svn add --force $WORKSPACE/Binaries/$newdir/*
#   $svn st $WORKSPACE/Binaries
#   $svn ci -m"Build with $JOB_NAME on $NODE_LABELS" --username svnjenkins --password $JENKINS_PASS  --non-interactive $WORKSPACE/Binaries
# fi
