REM Building on Legacy Microsoft Edge on Windows 10 VM (expired, see snapshot for info)

REM Note that this overrides the SVN version of SConstruct with the current copy on BHT20
REM to allow debugging of that

rem Run this in a window from "Open VS2022 Command developers"
rem N.B. Strawberry gfortran already installed

REM ============================================================
REM Somehow .exe files were not in the .tgz file! (3/2/24)
REM ============================================================


rem For future setup get MSVC get from https://developer.microsoft.com/en-us/windows/downloads/ go to "Download a VM"
rem (https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/) & get Parallels image
rem Install gcc & gfortran using this
rem https://github.com/LKedward/quickstart-fortran/releases/download/v1.9/quickstart-fortran-installer.exe
rem C:\quickstart_fortran\mingw64\bin\gcc.exe
rem C:\quickstart_fortran\mingw64\bin\gfortran.exe
rem PATH=C:\quickstart_fortran\mingw64\bin;%PATH%

set hostid="BHT20 VM: Legacy Microsoft Edge on Windows 10"
set SVN=C:\g2bld\anaconda_win64\svn.exe
rem mkdir C:\g2bld
set bldDir=c:\g2bld
set condaHome=%bldDir%\mf3

where gfortran

REM ================ Set up conda environment
rem curl -L -o %bldDir%\mf.exe https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-Windows-x86_64.exe
rem start /wait "" %bldDir%\mf.exe /InstallationType=JustMe /RegisterPython=0 /S /D=%condaHome%

call %condaHome%\Scripts\activate
echo on

set pyenv=py311
REM call conda env remove -n %pyenv% -y
rem call conda create -n %pyenv% -y python=3.11 wxpython numpy scipy matplotlib pyopengl pillow h5py imageio conda requests scons m2w64-ntldd-git
rem if ERRORLEVEL 1 exit /B 1

call %condaHome%\Scripts\activate %pyenv%
echo on
rem call conda info

cd %bldDir%
%svn% co -q https://subversion.xray.aps.anl.gov/pyGSAS/trunk GSAS-II
cd GSAS-II
REM rmdir AllBinaries /s /q
REM rmdir Binaries /s /q

cd fsource
copy \\Mac\Home\G2\GSASII\fsource\SConstruct SConstruct

call scons -c # clean up

if ERRORLEVEL 1 exit /B 1
call scons install=T

if ERRORLEVEL 1 exit /B 1
REM #=# find the build dir name; add info to Build notes
for /f "usebackq" %%i in ( `dir %bldDir%\GSAS-II\AllBinaries /ad /b` ) do set newdir=%%i
echo %newdir%

copy %bldDir%\GSAS-II\bin\Build.notes.txt %bldDir%\GSAS-II\AllBinaries\%newdir%
cd %bldDir%\GSAS-II\AllBinaries\%newdir%
echo Built with %hostid% from G2 version %SVN_REVISION% on %NODE_LABELS% >> Build.notes.txt
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" >> Build.notes.txt
call conda list -f python | findstr /B /C:# /V >> Build.notes.txt
call conda list -f numpy | findstr /B /C:# /V  >> Build.notes.txt
call conda list -f m2w64-gcc-fortran | findstr /B /C:# /V >> Build.notes.txt
ntldd %bldDir%\GSAS-II\AllBinaries\%newdir%\*.exe >> Build.notes.txt
ntldd %bldDir%\GSAS-II\AllBinaries\%newdir%\*.pyd >> Build.notes.txt

rem not installing c:\g2bld\mf3\envs\py311\python311.dll
rem c:\g2bld\mf3\envs\py311\Library\mingw-w64\bin\libgcc_s_seh-1.dll
rem c:\g2bld\mf3\envs\py311\Library\mingw-w64\bin\libwinpthread-1.dll
rem c:\g2bld\mf3\envs\py311\Library\mingw-w64\bin\libquadmath-0.dll
copy %CONDA_PREFIX%\Library\mingw-w64\bin\libgcc_s_seh-1.dll %bldDir%\GSAS-II\AllBinaries\%newdir%
copy %CONDA_PREFIX%\Library\mingw-w64\bin\libwinpthread-1.dll %bldDir%\GSAS-II\AllBinaries\%newdir%
copy %CONDA_PREFIX%\Library\mingw-w64\bin\libquadmath-0.dll %bldDir%\GSAS-II\AllBinaries\%newdir%

tar cvzf %bldDir%\\%newdir%.tgz *
copy %bldDir%\\%newdir%.tgz \\Mac\Home\Scratch\
echo copy %bldDir%\\%newdir%.tgz to release files in https://github.com/GSASII/binarytest/releases
echo copied to ~\Scratch on BHT20
