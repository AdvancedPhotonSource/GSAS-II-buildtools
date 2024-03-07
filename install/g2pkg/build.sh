#!/bin/bash
echo "running build.sh with RECIPE_DIR $RECIPE_DIR"
mkdir -p $PREFIX/bin
cp $RECIPE_DIR/../gitstrap.py $PREFIX/bin/gsas2-install.py
