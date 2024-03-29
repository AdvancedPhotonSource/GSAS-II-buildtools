REM ============================================================================
REM this creates the gsas2full self-installer for Windows from a git repository.
REM download this file with 
REM curl -L -O https://github.com/AdvancedPhotonSource/GSAS-II-buildtools/raw/main/localbuild/G2full_Win64.bat
REM ============================================================================
REM run manually on 1/24/2024 on BHT20 Windows 11 VM
c:
set WORKSPACE=\tmp
set condaHome=%WORKSPACE%\mf3
set builds=%WORKSPACE%\builds
mkdir %builds%
set gitInstallRepo=https://github.com/AdvancedPhotonSource/GSAS-II-buildtools.git
set gitCodeRepo=https://github.com/AdvancedPhotonSource/GSAS-II.git

set pyver=3.11
set numpyver=1.26

set packages=python=%pyver% wxpython numpy=%numpyver% scipy matplotlib pyopengl conda anaconda-client constructor conda-build git gitpython requests pillow h5py imageio scons pywin32

set env=bldpy311
REM # py 3.11.8 & np 1.26.4
set miniforge=https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Windows-x86_64.exe
REM https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe 

REM options to skip over sections, if already done

set install=
set install=True

set gitinstall=
set gitinstall=True

set makecomplete=
set makecomplete=True

REM ================ Install miniforge
if defined install (
   curl -L %miniforge% -o %WORKSPACE%\mambaforge.exe
   if exist %condaHome% (rmdir /s /q %condaHome%)
   echo Starting initial conda install, please wait
   start /wait "" %WORKSPACE%\mambaforge.exe /InstallationType=JustMe /RegisterPython=0 /S /D=%condaHome%
   call %condaHome%\Scripts\activate
   echo Starting 2nd conda install, please wait
   call conda create -n %env% -y %packages% -y -c conda-forge
   call conda env list
   )

call %condaHome%\Scripts\activate
call conda activate %env%
echo on

REM ================ Install GSAS-II repos
if defined gitinstall (
   echo Install Build and Code repos
   if exist %WORKSPACE%\GSAS2-build (rmdir /s /q %WORKSPACE%\GSAS2-build)
   git clone %gitInstallRepo% %WORKSPACE%\GSAS2-build --depth 1
   REM get the GSAS-II code to get the latest version number etc.
   if exist %WORKSPACE%\GSAS2-code (rmdir /s /q %WORKSPACE%\GSAS2-code)
   git clone %gitCodeRepo% %WORKSPACE%\GSAS2-code --depth 50
   )


cd %WORKSPACE%\GSAS2-build\install
echo python setgitversion.py %WORKSPACE%\GSAS2-code
     python setgitversion.py %WORKSPACE%\GSAS2-code

REM ================ create gsas2complete with conda-build
if defined makecomplete (

   call conda build purge
   call conda build purge-all
   call conda build g2complete -c conda-forge --output-folder %builds% --numpy %numpyver%
)

rem =========== Build the gsas2full self-installer & someday copy to web
del gsas2full*.exe
set CONDA_SOLVER=classic
call constructor --clean
call constructor g2full
exit /b
