REM ======================================================================
REM echo "Finish up GSAS-II installation"
REM final steps in GSAS-II installation are now in post-link.bat (conda package)
REM ======================================================================
exit

REM
set python=%PREFIX%\python.exe
set gitstrap=%PREFIX%\gitstrap.py
set logfile=%PREFIX%\g2post_out.log
set gitlog1=%PREFIX%\gitstrap1.log
set gitlog2=%PREFIX%\gitstrap2.log
REM
echo %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog1% --noshortcut >> %logfile%
REM finish installation
echo %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
     %python% %gitstrap% --nocheck --log=%gitlog2% --nodownload >> %logfile%
