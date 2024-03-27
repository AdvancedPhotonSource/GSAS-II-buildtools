# Build gsas2pkg conda package Using toby@s11bmbcda.xray.aps.anl.gov
# using Mambaforge-23.11.0-0-Linux-x86_64.sh to create conda in  /tmp/mf3
# run 3/24/2024
#=========================================================================
cd /tmp
curl -L https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-Linux-x86_64.sh -O
bash Mambaforge-23.11.0-0-Linux-x86_64.sh -b -p /tmp/mf3
source /tmp/mf3/bin/activate
conda create -y -n bldG2pkg python=3.11 conda-build anaconda-client
conda activate bldG2pkg

git clone https://github.com/GSASII/GSASIIbuildtools.git /tmp/G2
cd /tmp/G2/install
conda build g2pkg  -c conda-forge --output-folder /tmp/build --numpy 1.26
conda build purge
anaconda upload /tmp/build/linux-64/gsas2pkg-*.tar.bz2 -i -u briantoby

# =========================================================================
# test install (separate window)
\tmp\mf3\Scripts\activate
conda create -n g2pkg briantoby::gsas2pkg
