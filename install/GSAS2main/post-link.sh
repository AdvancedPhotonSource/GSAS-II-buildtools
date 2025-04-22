#!/bin/bash
logfile=/tmp/G2complete_postlink.log
#
#============= Restore the git repository file
#
echo Completing install of GSAS-II from conda package > $logfile
mv -v $PREFIX/GSAS-II/keep_git $PREFIX/GSAS-II/.git >> $logfile 2>&1
mv -v $PREFIX/GSAS-II/keep.gitignore $PREFIX/GSAS-II/.gitignore >> $logfile 2>&1
#
# This does not run gitstrap.py here because it is assumed that will
# happen later when the conda constructor installer runs. If this package
# is ever to be used independently, it should be run here.
