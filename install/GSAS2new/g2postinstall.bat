REM ======================================================================
REM Finish up GSAS-II installation by trying to update GSAS-II 
REM and create a shortcut
REM ======================================================================

set python=%PREFIX%\python.exe
set gitstrap=%PREFIX%\gitstrap.py
set logfile=%PREFIX%\g2post_out.log
set gitlog1=%PREFIX%\gitstrap1.log
set gitlog2=%PREFIX%\gitstrap2.log
REM
echo Updating GSAS-II with gitstrap.py > %logfile%
echo %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
REM finish installation
echo %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
