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

for file in $(ls $RES_PATH/*.repos)
do
  echo "import repositories from $file."
  vcs import . < $file --skip-existing
done

if [ -d "$REPO_PATH" ]; then
  for file in $(ls $RES_PATH/*.repos)
  do
    echo "pull repositories from $file."
    vcs pull . < $file
  done
fi

rm -rf layers/*

if [ -d "$REPO_PATH" ]; then
  if [ ! -d "$LAYER_PATH" ]; then
    mkdir "$LAYER_PATH"
  fi
  if [ ! -e "$LAYER_PATH/.templateconf" ]; then
    touch "$LAYER_PATH/.templateconf"
  fi
  for file in $(ls $RES_PATH/link_*)
  do
    while IFS= read -r line; do
      ln -fs "$GIT_ROOT/$line" $GIT_ROOT/layers/${line##*/}
    done < $file
  done
fi

echo "Init done."
