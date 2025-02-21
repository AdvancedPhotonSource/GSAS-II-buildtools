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
REM This does not run gitstrap.py here because it is assumed that will
REM happen later when the conda constructor installer runs. If this package
REM is ever to be used independently, it should be run here.
REM likewise, see g2postinstall.bat for commands that 
