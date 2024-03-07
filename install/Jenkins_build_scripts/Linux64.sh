#which gfortran  # in /bin
#gfortran -v
gcc -v
#which svn       # in /bin
#find /usr/local -name "libquadmath*dylib" -print
#find /usr/local -name "libgcc*dylib" -print
svn=/bin/svn
condaHome=$WORKSPACE/conda
env=py10np123
sysType=linux-64
miniforge=https://github.com/conda-forge/miniforge/releases/download/22.9.0-2/Miniforge3-22.9.0-2-Linux-x86_64.sh
#compile=True
compile=False
build=True
upload=True
#========== Anaconda stuff
#wget $miniforge -O ./Miniconda3-latest.sh 
#bash ./Miniconda3-latest.sh -b -p $condaHome
#rm ./Miniconda3-latest.sh 
#set +x
#echo 'source $condaHome/bin/activate'
#      source $condaHome/bin/activate
#conda create -n $env python=3.10 wxpython=4.1 numpy=1.23 scipy matplotlib pyopengl  pillow h5py imageio conda requests anaconda-client constructor conda-build scons
#     conda install gcc gfortran subversion -y
set +x
echo 'source $condaHome/bin/activate $env'
      source $condaHome/bin/activate $env
#echo conda install gcc gfortran -y
#     conda install gcc gfortran -y
#echo conda install subversion -y
#     conda install subversion -y
FLIBloc=$CONDA_PREFIX/lib/  # location of library files for exe and .so files
svn=`which svn`
echo 'using svn from $svn'
#dir $FLIBloc/lib*
#exit
#conda info
#which gcc 
#which gfortran
#exit


#set -x
#=# Get anaconda gfortran into path
#which gfortran
#find $condaHome -name "*gfortran*"
#gfortdir=$condaHome/envs/py39/bin
#glibdir=$condaHome/envs/py39/x86_64-conda-linux-gnu/sysroot/lib64
#ln -sf $gfortdir/x86_64-conda-linux-gnu-gfortran $condaHome/bin/gfortran
#rm -rf GSAS-II/AllBinaries
#rm -rf GSAS-II/Binaries
#svn co -q https://subversion.xray.aps.anl.gov/pyGSAS/Binaries GSAS-II/Binaries
#cd ./GSAS-II/fsource

#==================================== Build of .so files ==================================
if [ "$compile" = "True" ]
then
  #=======================
  # get source code
  #=======================
  #rm -rf $WORKSPACE/GSASII
  #mkdir -p $WORKSPACE/GSASII
  $svn co https://subversion.xray.aps.anl.gov/pyGSAS/trunk/fsource $WORKSPACE/GSASII/fsource
  ########################
  # start compile process
  ########################
  # START debug stuff
  set -x
  which python
#  export FORTpath="/bin"
#  which $FORTpath/gfortran
#  export FLIBloc="/usr/local/opt/gcc/lib/gcc/current/"

  rm -rf GSASII/AllBinaries
  cd $WORKSPACE/GSASII/fsource

  scons -c # cleanup old
  set +x
  scons install=T # LIBGCC=T LIBGFORTRAN=T 
  # document build
  #=# find the build dir name; add info to Build notes
  newdir=`cd ../AllBinaries/; ls -d linux_64*`
  echo $newdir
  set -x
  ldd ../AllBinaries/$newdir/*.so
  ldd ../AllBinaries/$newdir/convcell
  ldd ../AllBinaries/$newdir/LATTIC
  cp ../bin/Build.notes.txt ../AllBinaries/$newdir/
  echo "Built with Jeeves from $JOB_NAME from G2 version $SVN_REVISION on $NODE_LABELS" >> ../AllBinaries/$newdir/Build.notes.txt
  cat /etc/os-release >> ../AllBinaries/$newdir/Build.notes.txt
  conda list -f python | tail -1 >> ../AllBinaries/$newdir/Build.notes.txt
  conda list -f numpy | tail -1 >> ../AllBinaries/$newdir/Build.notes.txt
  #conda list -f gfortran_linux-64 | tail -1 >> ../AllBinaries/$newdir/Build.notes.txt
  echo "Using gfortran (info follows)" >> ../AllBinaries/$newdir/Build.notes.txt
  gfortran -v 2>> ../AllBinaries/$newdir/Build.notes.txt
  #================
  # Upload binaries
  #================
  $svn co -q https://subversion.xray.aps.anl.gov/pyGSAS/Binaries $WORKSPACE/Binaries
fi

if [[ ("$compile" = "True") && (! -d $WORKSPACE/Binaries/$newdir) ]]
then
    mkdir $WORKSPACE/Binaries/$newdir
    $svn add $WORKSPACE/Binaries/$newdir
fi

if [ "$compile" = "True" ]
then
  cp ../AllBinaries/$newdir/* $WORKSPACE/Binaries/$newdir
  cp $FLIBloc/libgfortran.so.5  $WORKSPACE/Binaries/$newdir/
  cp $FLIBloc/libgcc_s.so.1     $WORKSPACE/Binaries/$newdir/
  cp $FLIBloc/libquadmath.so.0  $WORKSPACE/Binaries/$newdir/
  echo Uploading
  $svn add --force $WORKSPACE/Binaries/$newdir/*
  $svn st $WORKSPACE/Binaries
  $svn ci -m"Build with $JOB_NAME on $NODE_LABELS" --username svnjenkins --password $JENKINS_PASS  --non-interactive $WORKSPACE/Binaries
fi

#
#=========================== Build of g2complete package ==================================
#
#=============================
# Use commands below to build
#=============================
if [ "$build" = "True" ]
then
	set -x
	cd $WORKSPACE/GSAS-II/install
	python setversion.py
	mkdir -p ~/builds
	rm -rf ~/builds/*
	set +x
	echo conda build purge
    	 conda build purge
	echo conda build g2complete --output-folder ~/builds
    	 conda build g2complete --output-folder ~/builds
	set -x
    #ls -ltR ~/builds
    rm -rf ./gsascomplete*.tar.bz2
    cp ~/builds/$sysType/gsas* ./  # keep the conda package for debugging
	#
	#=========================== Build/upload of g2full installer =============================
	#
	# Build the self-installer
	rm -f *.sh
	constructor g2full
	set -x
	ls -l *.sh
	#ls -l *.*
fi

if [ "$upload" = "True" ]
then
	echo upload build
	# copy to "Latest" and upload
	#cp gsas2full-*-MacOSX-x86_64.sh gsas2full-Latest-MacOSX-x86_64.sh
	# copy to https://subversion.xray.aps.anl.gov/admin_pyGSAS/downloads/gsas2full-*-MacOSX-x86_64.sh
	scp gsas2full-*.sh svnpgsas@s11bmbcda.xray.aps.anl.gov:/home/joule/SVN/subversion/pyGSAS/downloads/
	#echo files found at https://subversion.xray.aps.anl.gov/admin_pyGSAS/downloads/gsas2full-*-MacOSX-x86_64.sh
	#ssh svnpgsas@s11bmbcda.xray.aps.anl.gov ls -lt /home/joule/SVN/subversion/pyGSAS/downloads/gsas2full-*-Linux-*.sh
fi
