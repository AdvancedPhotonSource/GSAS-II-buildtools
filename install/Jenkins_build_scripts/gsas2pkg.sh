# build gsas2pkg
source /Users/toby/mf3-x86/bin/activate
conda create -n build anaconda-client constructor conda-build 
conda activate build
cd ~/G2/install
conda build g2pkg --output-folder /tmp/install
conda convert --platform all /tmp/install/osx-64/gsas2pkg-3.0.0-0.tar.bz2 -o /tmp/install
#anaconda upload noarch/gsas2pkg-3.0.0-0.tar.bz2
anaconda upload /tmp/install/*/gsas2pkg-3.0.0-0.tar.bz2
