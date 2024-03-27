# Build gsas2pkg conda package Using on BHT20; create conda in  /tmp/mf3
# run 3/26/2024
#=========================================================================
cd /tmp
#curl -L https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-Linux-x86_64.sh -O
bash /Users/toby/Downloads/Mambaforge-23.11.0-0-MacOSX-x86_64.sh -b -p /tmp/mf3
source /tmp/mf3/bin/activate
conda create -y -n bldG2pkg python=3.11 conda-build anaconda-client git gitpython
conda activate bldG2pkg

git clone https://github.com/AdvancedPhotonSource/GSAS-II-buildtools.git /tmp/G2
cd /tmp/G2/install
conda build purge
conda build g2pkg  -c conda-forge --output-folder /tmp/build --numpy 1.26
# need to change this somehow to use anaconda token in GH actions repository secrets
anaconda upload /tmp/build/linux-64/gsas2pkg-*.tar.bz2 -i -u briantoby
conda build purge

REM =========================================================================
REM test install (separate window)
\tmp\mf3\Scripts\activate
conda create -n g2pkg briantoby::gsas2pkg
