set logfile=\tmp\conda_G2postbuild.log
echo Preparing to install GSAS-II from GitHub > %logfile%
# create scripts that might be of use for GSAS-II
REM create bootstrap batch file ================================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\start_G2_bootstrap.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\start_G2_bootstrap.bat"
echo python %PREFIX%\gitstrap.py >> "%PREFIX%\start_G2_bootstrap.bat"
REM create shortcut to start GSAS-II     =======================================
echo REM Commands to run GSAS-II load/update process > "%PREFIX%\start_GSASII.bat"
echo call %PREFIX%\Scripts\activate >> "%PREFIX%\start_GSASII.bat"
echo python %PREFIX%\GSASII\GSASII.py >> "%PREFIX%\start_GSASII.bat"
REM 
REM ============= Restore the git repository file
REM 
echo fit git files >> %logfile%
echo rename %PREFIX%\GSASII\keep_git %PREFIX%\GSASII\.git >> %logfile%
     rename %PREFIX%\GSASII\keep_git %PREFIX%\GSASII\.git >> %logfile%
if errorlevel 1 exit 1
echo rename %PREFIX%\GSASII\keep.gitignore %PREFIX%\GSASII\.gitignore >> %logfile%
     rename %PREFIX%\GSASII\keep.gitignore %PREFIX%\GSASII\.gitignore >> %logfile%
if errorlevel 1 exit 1
