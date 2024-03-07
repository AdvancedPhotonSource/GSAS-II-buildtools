REM =======================================================================
REM this is taken from Jenkins where it is used to compile and package
REM GSAS-II
REM =======================================================================
REM 
REM ================ Install miniforge
set condaHome=C:\jenkins\miniforge3
REM curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe
REM rmdir %condaHome% /s /q
REM start /wait "" Miniforge3-Windows-x86_64.exe /InstallationType=JustMe /RegisterPython=0 /S /D=%condaHome%

REM ================ Set up conda environment
REM everything needed by GSAS-II
set env=py3.10n1.23
REM call %condaHome%\Scripts\activate
REM call conda env remove -n %env% -y
REM call conda create -n %env% -y python=3.10 wxpython=4.1 numpy=1.23 scipy matplotlib pyopengl  pillow h5py imageio conda requests

REM minimum needed to build & package (w/o compiler)
REM call conda create -n %env% -y python=3.10 numpy=1.23 scons wxpython=4.1 matplotlib anaconda-client constructor conda-build -y
if ERRORLEVEL 1 exit 1
REM call conda env list
call %condaHome%\Scripts\activate %env%
if ERRORLEVEL 1 exit 1

REM Debug dependencies 
REM call conda install m2w64-ntldd-git

REM where gfortran
REM gfortran -v
set dllHome=C:\Strawberry\c\bin\
REM dir /s %dllHome%

REM====== Setup Subversion 
REM where svn
REM set svn=C:\Jenkins\conda37-64\envs\svn\Library\bin\svn.exe
REM rmdir %HOME%\svn /s /q
REM %svn% export https://subversion.xray.aps.anl.gov/pyGSAS/install/svn/anaconda_win64 %HOME%\svn
path=%HOME%\svn;%path%
where svn
set svn=svn
svn --version --quiet

REM====== Build GSAS-II binaries
cd GSAS-II
%svn% --version
rmdir AllBinaries /s /q
rmdir Binaries /s /q

%svn% co -q https://subversion.xray.aps.anl.gov/pyGSAS/Binaries Binaries
cd fsource
call scons -c # clean up
if ERRORLEVEL 1 exit 1
call scons install=T
if ERRORLEVEL 1 exit 1
REM #=# find the build dir name; add info to Build notes
for /f "usebackq" %%i in ( `dir ..\AllBinaries /ad /b` ) do set newdir=%%i
echo %newdir%
REM ntldd ..\AllBinaries\%newdir%\*.exe
REM ntldd ..\AllBinaries\%newdir%\*.pyd

copy Build.notes.txt ..\AllBinaries\%newdir%
cd ..\AllBinaries\%newdir%
echo Built with Jeeves from %JOB_NAME% from G2 version %SVN_REVISION% on %NODE_LABELS% >> Build.notes.txt
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" >> Build.notes.txt
call conda list -f python | findstr /B /C:# /V >> Build.notes.txt
call conda list -f numpy | findstr /B /C:# /V  >> Build.notes.txt
call conda list -f m2w64-gcc-fortran | findstr /B /C:# /V >> Build.notes.txt

REM====== upload binaries to svn server
cd ..
dir
mkdir ..\Binaries\%newdir%
copy /y %newdir%\* ..\Binaries\%newdir%
dir %dllHome%\*.dll
rem== Note: see https://anaconda.org/msys2/m2w64-ntldd-git for a utility that can find dependencies.
rem== (files libgcc_s_dw2-1.dll, libgmp-10.dll, libquadmath-0.dll, libgfortran-3.dll, libgmpxx-4.dll, libwinpthread-1.dll)
REM copy /y %dllHome%\libgcc*.dll ..\Binaries\%newdir%
REM copy /y %dllHome%\libgmp*.dll ..\Binaries\%newdir%
REM copy /y %dllHome%\libquadmath*.dll ..\Binaries\%newdir%
copy /y %dllHome%\libgfortran*.dll ..\Binaries\%newdir%
REM copy /y %dllHome%\libwinpthread*.dll ..\Binaries\%newdir%
%svn% add --no-ignore ..\Binaries\%newdir%
%svn% add --no-ignore ..\Binaries\%newdir%\*
%svn% st ..\Binaries\%newdir%
%svn% ci -m"Build with %JOB_NAME% on %NODE_LABELS%" --username svnjenkins --password %JENKINS_PASS%  --non-interactive ..\Binaries

REM====== Create installer & upload 
cd ..
cd ..
%svn% co -q https://subversion.xray.aps.anl.gov/pyGSAS/install install
if ERRORLEVEL 1 exit 1
cd install
call conda build purge
call conda build purge-all
python setversion.py
if ERRORLEVEL 1 exit 1
echo off
call conda build g2complete -c conda-forge --output-folder C:\Jenkins\g2builds 
if ERRORLEVEL 1 exit 1
rem =========== Build the self-installer & copy to web
del gsas2full*.exe
call constructor --clean
call constructor g2full
if ERRORLEVEL 1 exit 1
REM make copy of current version as "latest"
for /f "usebackq" %%i in ( `dir gsas2full*.exe /b` ) do copy %%i gsas2full-Latest-Windows-x86_64.exe
for /f "usebackq" %%i in ( `dir gsas2full*.exe /b` ) do scp %%i svnpgsas@s11bmbcda.xray.aps.anl.gov:/home/joule/SVN/subversion/pyGSAS/downloads
