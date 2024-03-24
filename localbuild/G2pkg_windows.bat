REM Build gsas2pkg conda package Using Windows 11 VM on BHT20
REM use Mambaforge-23.11.0-0-Windows-x86_64.exe to create conda in  \tmp\mf3\
REM run 3/24/2024
REM =========================================================================
cd \tmp\mf3
Scripts\activate
conda create -n bldG2pkg python=3.11 git gitpython conda-build anaconda-client
conda activate bldG2pkg
git clone https://github.com/GSASII/GSASIIbuildtools.git \tmp\G2
cd \tmp\G2\install
conda build g2pkg  -c conda-forge --output-folder c:\tmp --numpy 1.26
anaconda upload c:/tmp/win-64/gsas2pkg-*.tar.bz2 -i -u briantoby
conda build purge

REM =========================================================================
REM test install (separate cmd window)
\tmp\mf3\Scripts\activate
conda create -n g2pkg briantoby::gsas2pkg
