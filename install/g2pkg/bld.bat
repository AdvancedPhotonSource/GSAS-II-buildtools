if not exist "%PREFIX%\Scripts" (
   mkdir "%PREFIX%\Scripts"
   if errorlevel 1 exit 1
)
copy %RECIPE_DIR%\..\gitstrap.py %PREFIX%\Scripts\gsas2-install.py
if errorlevel 1 exit 1
