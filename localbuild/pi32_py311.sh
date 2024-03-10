hostid="Linux pi32 6.1.0-rpi7-rpi-v7 armv7l"
# no conda for 32-bit raspberry Pi so this requires a lot more fiddling
# see https://subversion.xray.aps.anl.gov/trac/pyGSAS/wiki/InstallPiLinux#a2.InstallingGSAS-IIon32-bitRaspberryPiOS

WORKSPACE=/tmp/g2py3.11
if [ ! -e "$WORKSPACE" ]; then
    mkdir $WORKSPACE
    echo mkdir $WORKSPACE
fi

set -x
svn=svn

install=True
install=False

compile=True
#compile=False

if [ "$install" = "True" ]
then
    sudo apt update
    sudo apt full-upgrade
    sudo apt autoremove

    sudo apt install subversion lxterminal wget xemacs21 python3-ipython
    sudo apt install gfortran scons python3-numpy
    ## installs py3.11.2, np 1.24.2
    #sudo apt install python3-wxgtk4.0 # needed to build wx
    #sudo apt install python3-scipy python3-matplotlib python3-opengl python3-pil python3-h5py python3-imageio # needed to run GSAS-II
fi

#==================================== Build of .so files ==================================
newdir="fail"
if [ "$compile" = "True" ]
then
  $svn co https://subversion.xray.aps.anl.gov/pyGSAS/trunk/fsource $WORKSPACE/GSASII/fsource
  which python
  gfortran -v
  rm -rf GSASII/AllBinaries
  cd $WORKSPACE/GSASII/fsource

  scons -c # cleanup old
  set +x
  scons install=T # LIBGFORTRAN=T LIBGCC=T 
  # document build
  #=# find the build dir name; add info to Build notes
  newdir=`cd $WORKSPACE/GSASII/AllBinaries/; ls -d linux*`
  echo $newdir
  #set -x
  cp $WORKSPACE/GSASII/bin/Build.notes.txt $WORKSPACE/GSASII/AllBinaries/$newdir/
  SVN_REVISION="`svn info https://subversion.xray.aps.anl.gov/pyGSAS/trunk/fsource | grep Revision`"
  echo "Built on $hostid from $SVN_REVISION" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  python -c "import sys; print(f'Python: {sys.version}')" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  python -c "import numpy; print(f'numpy: {numpy.__version__}')" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  echo "Using `which gfortran`, info follows" >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  gfortran -v 2>> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  ldd $WORKSPACE/GSASII/AllBinaries/$newdir/* >> $WORKSPACE/GSASII/AllBinaries/$newdir/Build.notes.txt
  if [ ! -d $WORKSPACE/GSASII/AllBinaries/$newdir ]; then   # this is not working at present
	echo $WORKSPACE/GSASII/AllBinaries/$newdir not found
	exit
  fi
  cd $WORKSPACE/GSASII/AllBinaries/$newdir
  cp /lib/arm-linux-gnu*/libgcc_s.so.1 .
  cp /lib/arm-linux-gnu*/libgfortran.so.5 .
  tar cvzf /tmp/$newdir.tgz *
  echo "Add /tmp/$newdir.tgz to binary release in https://github.com/GSASII/binarytest/releases"
fi
