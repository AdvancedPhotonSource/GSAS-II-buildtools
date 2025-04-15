#!/bin/bash
# this is run after the gsas2new...sh installer is run. It updates to the latest GSAS-II
# version and creates shortcuts
logfile=/tmp/g2post_out.log
gitlog1=/tmp/gitcompile.log
gitlog2=/tmp/gitcompile.log
echo "Finish up GSAS-II installation"
# update the GSAS-II package if possible, create shortcuts & byte-compile...
echo "launching bootstrap process"
# try to update to latest GSAS-II version (will fail if no network)
source $PREFIX/bin/activate
echo python $PREFIX/gitcompile.py --nocompile --nocheck --log=$gitlog1 --noshortcut >> $logfile 2>&1
     python $PREFIX/gitcompile.py --nocompile --nocheck --log=$gitlog1 --noshortcut >> $logfile 2>&1
# finish installation by creating platform-specific shortcuts
echo python $PREFIX/gitcompile.py --nocompile --nocheck --log=$gitlog2 --nodownload >> $logfile 2>&1
     python $PREFIX/gitcompile.py --nocompile --nocheck --log=$gitlog2 --nodownload >> $logfile 2>&1
#============================================================================
#============================================================================
# create script shortcuts that might be of use
#============================================================================
# create bootstrap-reset script
resetScript=$PREFIX/bin/reset-gsasII.sh
echo "# Commands to run GSAS-II load/update process" > $resetScript
echo "source $PREFIX/bin/activate" >> $resetScript
echo "$PREFIX/bin/python $PREFIX/gitcompile.py --reset" >>  $resetScript
chmod +x $resetScript
#============================================================================
# create start script
startScript=$PREFIX/bin/gsasII.sh
echo "# Commands to start GSAS-II" > $startScript
echo "source $PREFIX/bin/activate" >> $startScript
echo "$PREFIX/bin/python $PREFIX/GSAS-II/GSASII/G2.py \$*" >> $startScript
chmod +x $startScript
#============================================================================
#============================================================================
echo "GSAS-II installer completed"
if [[ "$OSTYPE" == "darwin"* ]]; then 
    echo "*** GSAS-II app will be highlighted in Finder ***"
    echo "***   you may wish to drag it to the dock.    ***"
fi
