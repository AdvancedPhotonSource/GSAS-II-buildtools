REM ======================================================================
echo "Finish up GSAS-II installation"
REM ======================================================================
set python=%PREFIX%\python.exe
set gitstrap=%PREFIX%\gitstrap.py
set logfile=%PREFIX%\g2post_out.log
set gitlog1=%PREFIX%\gitstrap1.log
set gitlog2=%PREFIX%\gitstrap2.log
REM ======================================================================
echo %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
REM finish installation
echo %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
REM create bootstrap batch file ================================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_bootstrap.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_bootstrap.bat"
echo python %gitstrap% >> "%PREFIX%\G2_bootstrap.bat"
REM create shortcut to start GSAS-II     =======================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\G2_start.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\G2_start.bat"
echo python %PREFIX%\GSAS-II\GSASII\G2.py >> "%PREFIX%\G2_start.bat"
set errorlevel=0
exit 0
