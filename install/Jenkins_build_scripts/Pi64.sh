#svn=svn # gets set later
WORKSPACE=~/g2bld
mkdir -p $WORKSPACE
condaHome=$WORKSPACE/conda
env=py10np123
sysType=linux_arm64       # compile directory prefix 
buildType=linux-aarch64   # build output directory name
miniforge=https://github.com/conda-forge/miniforge/releases/download/22.9.0-2/Miniforge3-22.9.0-2-Linux-aarch64.sh
#compile=True
build=True
upload=True
#installPython=True
#installApt=True
#makewx=True

if [ "$installApt" = "True" ]
then
    #sudo apt-get update
    # useful to find packages
    # apt list > /tmp/apt.list

    sudo apt-get install emacs -y
    sudo apt-get install subversion -y
    sudo apt-get install gfortran -y
    # 
    # from https://wiki.wxpython.org/BuildWxPythonOnRaspberryPi
    #### sudo apt-get install dpkg-dev build-essential libjpeg-dev libtiff-dev libsdl1.2-dev libgstreamer-plugins-base0.10-dev libnotify-dev freeglut3 freeglut3-dev libwebkitgtk-dev libghc-gtk3-dev libwxgtk3.0-gtk3-dev
    # with BHT updates
    sudo apt-get install dpkg-dev build-essential libjpeg-dev libtiff-dev libsdl1.2-dev libgstreamer-plugins-base1.0-dev libnotify-dev freeglut3 freeglut3-dev libwebkit2gtk-4.0-dev libghc-gtk3-dev libwxgtk3.0-gtk3-dev
fi

#
#========== setup Anaconda
if [ "$installPython" = "True" ]
then
    wget $miniforge -O ./Miniconda3-latest.sh 
    bash ./Miniconda3-latest.sh -b -p $condaHome
    #rm ./Miniconda3-latest.sh 
    set +x
    echo source $condaHome/bin/activate
    source $condaHome/bin/activate
    conda update -n base -c conda-forge conda -y
    conda create -y -n $env python=3.10 numpy=1.23 scipy matplotlib pyopengl  pillow h5py imageio conda requests anaconda-client constructor conda-build scons 
    # wxpython=4.1 
    #     conda install gcc gfortran subversion -y
    set +x
fi
echo source $condaHome/bin/activate $env
     source $condaHome/bin/activate $env

#============= build wxPython (see
# https://wxpython.org/blog/2017-08-17-builds-for-linux-with-pip/index.html)
if [ "$makewx" = "True" ]
then
    conda install pip six wheel setuptools attrdict3
    mkdir -p ~/bldWx
    cd ~/bldWx
    pip download wxPython==4.2.0 # gets wxPython-4.2.0.tar.gz 
    pip wheel -v wxPython-4.2.0.tar.gz  2>&1 | tee /tmp/build.log  # 1.5 Hr on Pi400
    pip install wxPython-4.2.0-cp310-cp310-linux_aarch64.whl # for testing
    cd 
fi

svn=`which svn`
echo 'using svn from $svn'

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
  
  rm -rf GSASII/AllBinaries
  cd $WORKSPACE/GSASII/fsource

  scons -c # cleanup old
  set +x
  scons install=T LIBGCC=T LIBGFORTRAN=T 
  # document build
  #=# find the build dir name; add info to Build notes
  newdir=`cd ../AllBinaries/; ls -d $sysType*`
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
  echo Uploading
  $svn add --force $WORKSPACE/Binaries/$newdir/*
  $svn st $WORKSPACE/Binaries
  $svn ci -m"Build with Pi64.sh on Pi400/Bullseye" $WORKSPACE/Binaries --username toby
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
	svn co -q https://subversion.xray.aps.anl.gov/pyGSAS/install $WORKSPACE/install
	cd $WORKSPACE/install
	python setversion.py
	mkdir -p ~/builds
	rm -rf ~/builds/*
	set +x
	echo conda build purge
	conda build purge
	conda build g2complete --output-folder ~/builds
	set -x
#    ls -ltR ~/builds
#    rm -rf ./gsascomplete*.tar.bz2
#    cp ~/builds/$buildType/gsas* ./  # keep the conda package for debugging
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
	#cp gsas2full-*-Linux-aarch64.sh gsas2full-Latest-Linux-aarch64.sh
	# copy to https://subversion.xray.aps.anl.gov/admin_pyGSAS/downloads/gsas2full-*-Linux-aarch64.sh
	scp gsas2full-*.sh toby@xgate.xray.aps.anl.gov:staged/
	echo remember to copy staged file to /home/joule/SVN/subversion/pyGSAS/downloads/ using svnpgsas@s11bmbcda.xray.aps.anl.gov
	echo and create gsas2full-Latest-Linux-aarch64.sh
	#echo list files found at https://subversion.xray.aps.anl.gov/admin_pyGSAS/downloads/gsas2full-*-Linux-aarch64.sh
	#ssh toby@s11bmbcda.xray.aps.anl.gov ls -lt /home/joule/SVN/subversion/pyGSAS/downloads/gsas2full-*-Linux-*.sh
fi
