#!/bin/bash
# Initlize Yocto Environment
#
GIT_ROOT=$(git rev-parse --show-toplevel | xargs echo -n)
REPO_PATH=$GIT_ROOT/repos
RES_PATH=$GIT_ROOT/resources
LAYER_PATH=$GIT_ROOT/layers
SCRIPT_PATH=$GIT_ROOT/scripts

if ! command -v vcs &> /dev/null
then
    echo "vcstool not found, install it, please."
    exit
fi

if [ -d "$REPO_PATH" ]; then
  for file in $(ls $RES_PATH/*.repos)
  do
    echo "pull repositories from $file."
    vcs pull . < $file
  done
else
  for file in $(ls $RES_PATH/*.repos)
  do
    echo "import repositories from $file."
    vcs import . < $file
  done
fi

if [ -d "$REPO_PATH" ]; then
  for file in $(ls $RES_PATH/link_*)
  do
    while IFS= read -r line; do
      ln -fs "$GIT_ROOT/$line" $GIT_ROOT/layers/${line##*/}
      echo $line
    done < $file
  done
fi
