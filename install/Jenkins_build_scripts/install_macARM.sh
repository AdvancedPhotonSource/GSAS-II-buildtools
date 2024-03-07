setopt interactivecomments
# This script is used to install GSAS-II onto an ARM ("Apple Silicon", M1 etc)
# computer where a self-installer cannot be prepared.
#
# 0) define locations to be used
InstallLoc=~/gsas2full   # change this if desired to install in a different location
GSAS2loc=$InstallLoc/GSASII
miniforge=https://github.com/conda-forge/miniforge/releases/download/22.9.0-2/Miniforge3-22.9.0-2-MacOSX-arm64.sh
#
# 1) install conda-forge Python 
tmpMFloc=/tmp/Miniconda3-latest.sh 
curl -L $miniforge -o $tmpMFloc
bash $tmpMFloc -b -p $InstallLoc
rm /tmp/Miniconda3-*.sh 
source $InstallLoc/bin/activate
#
# 2) install the Python packages needed by GSAS-II
conda install python=3.10 wxpython=4.2 numpy=1.23 scipy matplotlib pyopengl pillow h5py imageio requests -y
#
# 3) Create a GSAS-II location and install the svn software 
mkdir -p $GSAS2loc/svn
curl -L https://subversion.xray.aps.anl.gov/pyGSAS/svndist/anaconda_mac64_svn.tar.gz -o /tmp/svn.tar.gz
cd $GSAS2loc/svn
tar xvzf /tmp/svn.tar.gz
#
# 5) get the GSAS-II self-installer script and install GSAS-II from the internet
cd ..
curl -L https://subversion.xray.aps.anl.gov/pyGSAS/install/bootstrap.py -o $GSAS2loc/bootstrap.py
python ./bootstrap.py
