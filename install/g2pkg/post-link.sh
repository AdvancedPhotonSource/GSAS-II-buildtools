#!/bin/bash
echo "Preparing to install GSAS-II from GitHub" > $PREFIX/G2conda_inst.log
#============================================================================
#============================================================================
# install and run the bootstrap
echo "running GSAS-II installer" >> $PREFIX/G2conda_inst.log 2>&1
mv $PREFIX/bin/gsas2-install.py $PREFIX/gitstrap.py >> $PREFIX/G2conda_inst.log 2>&1
# debug stuff
echo $CONDA_ROOT/bin/python  >> $PREFIX/G2conda_inst.log 2>&1
echo $PREFIX/bin/python  >> $PREFIX/G2conda_inst.log 2>&1
echo `which python`  >> $PREFIX/G2conda_inst.log 2>&1
# launch the GSAS-II installer script
$PREFIX/bin/python $PREFIX/gitstrap.py >> $PREFIX/G2conda_inst.log 2>&1
#============================================================================
#============================================================================
# create scripts that might be of use for GSAS-II
#============================================================================
# create bootstrap-reset script
resetScript=$PREFIX/bin/reset-gsasII.sh
echo "# Commands to run GSAS-II load/update process" > $resetScript
echo "source $CONDA_ROOT/bin/activate $CONDA_DEFAULT_ENV" >>  $resetScript
echo "$PREFIX/bin/python $PREFIX/gitstrap.py --reset" >>  $resetScript
chmod +x $resetScript
#============================================================================
# create start script
startScript=$PREFIX/bin/gsasII.sh
echo "# Commands to start GSAS-II" > $startScript
echo "source $CONDA_ROOT/bin/activate $CONDA_DEFAULT_ENV" >> $startScript
echo "$PREFIX/bin/python $PREFIX/GSASII.py \$*" >> $startScript
chmod +x $startScript
#============================================================================
