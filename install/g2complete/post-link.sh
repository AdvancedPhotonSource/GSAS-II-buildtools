#!/bin/bash
logfile=/tmp/conda_G2postbuild.log
#mkdir -p $PREFIX/GSASII
echo Preparing to install GSAS-II from GitHub > $logfile
# create scripts that might be of use for GSAS-II
# create bootstrap script
#echo "# Commands to run GSAS-II load/update process" > $CONDA_ROOT/start_G2_bootstrap.sh
#echo "source $CONDA_ROOT/bin/activate $CONDA_DEFAULT_ENV" >> $CONDA_ROOT/start_G2_bootstrap.sh
#echo "$PREFIX/bin/python $PREFIX/gitstrap.py" >> $CONDA_ROOT/start_G2_bootstrap.sh
# create start script
#echo "# Commands to start GSAS-II" > $CONDA_ROOT/start_GSASII.sh
#echo "source $CONDA_ROOT/bin/activate $CONDA_DEFAULT_ENV" >> $CONDA_ROOT/start_GSASII.sh
#echo "$PREFIX/bin/python $PREFIX/GSASII.py" >> $CONDA_ROOT/start_GSASII.sh
#
# install and run the bootstrap
echo fit git files >> $logfile
mv -v $PREFIX/GSASII/keep_git $PREFIX/GSASII/.git >> $logfile 2>&1
mv -v $PREFIX/GSASII/keep.gitignore $PREFIX/GSASII/.gitignore >> $logfile 2>&1
