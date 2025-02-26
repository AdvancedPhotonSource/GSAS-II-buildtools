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
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_bootstrap.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_bootstrap.bat"
echo python %gitstrap% >> "%PREFIX%\G2_bootstrap.bat"
REM
echo %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
REM finish installation
echo %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
echo post-link.bat now done >> %logfile%
