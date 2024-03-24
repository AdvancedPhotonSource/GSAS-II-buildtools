#!/bin/bash
#echo "Preparing to install GSAS-II from GitHub"
echo "Preparing to install GSAS-II from GitHub" > $PREFIX/G2conda_inst.log
# create scripts that might be of use for GSAS-II
# create bootstrap script
echo "# Commands to run GSAS-II load/update process" > $CONDA_ROOT/start_G2_bootstrap.sh
echo "source $CONDA_ROOT/bin/activate $CONDA_DEFAULT_ENV" >> $CONDA_ROOT/start_G2_bootstrap.sh
echo "$PREFIX/bin/python $PREFIX/gitstrap.py" >> $CONDA_ROOT/start_G2_bootstrap.sh
# create start script
echo "# Commands to start GSAS-II" > $CONDA_ROOT/start_GSASII.sh
echo "source $CONDA_ROOT/bin/activate $CONDA_DEFAULT_ENV" >> $CONDA_ROOT/start_GSASII.sh
echo "$PREFIX/bin/python $PREFIX/GSASII.py" >> $CONDA_ROOT/start_GSASII.sh
# install and run the bootstrap
echo "running GSAS-II installer" >> $PREFIX/G2conda_inst.log 2>&1
mv $PREFIX/bin/gsas2-install.py $PREFIX/gitstrap.py >> $PREFIX/G2conda_inst.log 2>&1
echo $CONDA_ROOT/bin/python  >> $PREFIX/G2conda_inst.log 2>&1
echo $PREFIX/bin/python  >> $PREFIX/G2conda_inst.log 2>&1
echo `which python`  >> $PREFIX/G2conda_inst.log 2>&1
$PREFIX/bin/python $PREFIX/gitstrap.py >> $PREFIX/G2conda_inst.log 2>&1
