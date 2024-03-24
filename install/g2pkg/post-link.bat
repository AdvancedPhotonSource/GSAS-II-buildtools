echo Installing GSAS-II from GitHub > "%PREFIX%\G2_bootstrap_out.log"
copy "%PREFIX%\Scripts\gsas2-install.py" "%PREFIX%\gitstrap.py"
REM ======================================================================
REM# create bootstrap batch file
echo REM Commands to run GSAS-II load/update process > "%CONDA_ROOT%\start_G2_bootstrap.bat"
echo call %CONDA_ROOT%\Scripts\activate %CONDA_DEFAULT_ENV% >> "%CONDA_ROOT%\start_G2_bootstrap.bat"
echo python %PREFIX%\gitstrap.py >> "%CONDA_ROOT%\start_G2_bootstrap.bat"
REM ======================================================================
REM# create start GSAS-II batch file
echo REM Commands to run GSAS-II load/update process > "%CONDA_ROOT%\start_GSASII.bat"
echo call %CONDA_ROOT%\Scripts\activate %CONDA_DEFAULT_ENV% >> "%CONDA_ROOT%\start_GSASII.bat"
echo python %PREFIX%\GSASII\GSASII.py >> "%CONDA_ROOT%\start_GSASII.bat"
REM
REM ======================================================================
REM# install and run the bootstrap
echo starting gitstrap.py >> "%PREFIX%\G2_bootstrap_out.log"
set "python=%PREFIX%\python.exe"
set "script=%PREFIX%\gitstrap.py"
"%python%" "%script%" --noprogress >> "%PREFIX%\G2_bootstrap_out.log"
echo completed gitstrap.py >> "%PREFIX%\G2_bootstrap_out.log"
set errorlevel=0
exit 0
