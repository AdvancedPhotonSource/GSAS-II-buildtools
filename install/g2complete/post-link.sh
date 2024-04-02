#!/bin/bash
logfile=/tmp/G2complete_postlink.log
echo Preparing to install GSAS-II from GitHub > $logfile
mv -v $PREFIX/GSAS-II/keep_git $PREFIX/GSAS-II/.git >> $logfile 2>&1
mv -v $PREFIX/GSAS-II/keep.gitignore $PREFIX/GSAS-II/.gitignore >> $logfile 2>&1
