#!/bin/bash
# based on output from makeBldFiles.py and then edited manually
echo '==================== running build.sh ===================='
logfile=/tmp/conda_G2build_out.log
gclog="/tmp/gitcompile.log"
rm -f $gclog
#
echo starting Build.sh > $logfile 2>&1
cp $RECIPE_DIR/../gitcompile.py $PREFIX/
echo ls $PREFIX/ >> $logfile 2>&1
echo git= >> $logfile 2>&1
which git >> $logfile 2>&1
echo python= >> $logfile 2>&1
which python >> $logfile 2>&1
echo python $PREFIX/gitcompile.py --nocheck --noshortcut --noprogress --log=$gclog --branch=main >> $logfile 2>&1
     python $PREFIX/gitcompile.py --nocheck --noshortcut --noprogress --log=$gclog --branch=main >> $logfile 2>&1
# rename the .git files so they get copied into the conda package
mv -v $PREFIX/GSAS-II/.git $PREFIX/GSAS-II/keep_git  >> $logfile 2>&1
mv -v $PREFIX/GSAS-II/.gitignore $PREFIX/GSAS-II/keep.gitignore  >> $logfile 2>&1
