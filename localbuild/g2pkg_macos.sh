# Build gsas2pkg conda package Using on BHT20; create conda in  /tmp/mf3
# run 3/27/2024
#=========================================================================
echo cleanup
rm -rf /tmp/G2 /tmp/mf3 /tmp/build

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
cd /tmp/build
conda convert /tmp/build/osx-64/gsas2pkg-*.tar.bz2 -p osx-arm64
# need to change this somehow to use anaconda token in GH actions repository secrets
conda build purge
anaconda upload /tmp/build/osx*/gsas2pkg-*.tar.bz2 -i -u briantoby

#=========================================================================
# test install (do in separate window)
#\tmp\mf3\Scripts\activate
#conda create -n g2pkg briantoby::gsas2pkg
