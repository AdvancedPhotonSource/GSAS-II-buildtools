set logfile=%PREFIX%\g2main_postlink.log
echo Completing install of GSAS-II from conda package > %logfile%
REM 
REM ============= Restore the git repository file
REM 
REM dir  >> %logfile%
echo restore git files >> %logfile%
cd %PREFIX%\GSAS-II
REM dir  >> %logfile%

echo C:\Windows\System32\tar.exe xzf git.tgz  >> %logfile%
     C:\Windows\System32\tar.exe xzf git.tgz  >> %logfile%
if errorlevel 1 exit 1

del /s git.tgz >> %logfile%
REM
REM create shortcut to start GSAS-II     =======================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_start.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_start.bat"
echo python %PREFIX%\GSAS-II\GSASII\G2.py >> "%PREFIX%\G2_start.bat"
REM create bootstrap batch file ================================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_bootstrap.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_bootstrap.bat"
echo post-link.bat now done >> %logfile%
