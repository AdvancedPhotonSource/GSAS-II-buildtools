set logfile=%PREFIX%\g2complete_postlink.log
echo Completing install of GSAS-II from conda package > %logfile%
REM 
REM ============= Restore the git repository file
REM 
echo fix git files >> %logfile%
cd %PREFIX%\GSAS-II

echo C:\Windows\System32\tar.exe xzf git.tgz  >> %logfile%
     C:\Windows\System32\tar.exe xzf git.tgz  >> %logfile%
if errorlevel 1 exit 1

del git.tgz >> %logfile%
REM
REM create shortcut to start GSAS-II     =======================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_start.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_start.bat"
echo python %PREFIX%\GSAS-II\GSASII\G2.py >> "%PREFIX%\G2_start.bat"
REM create bootstrap batch file ================================================
Note that these commands assume that gcc and gfortran are already installed. echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_bootstrap.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_bootstrap.bat"
echo python %gitstrap% >> "%PREFIX%\G2_bootstrap.bat"
echo PREFIX = %PREFIX%  >> %logfile%
echo PKG_NAME = %PKG_NAME% >> %logfile%
echo PKG_VERSION = %PKG_NAME% >> %logfile%
echo PKG_BUILDNUM = %PKG_BUILDNUM% >> %logfile%
echo post-link.bat now done >> %logfile%
