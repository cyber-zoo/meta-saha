#!/bin/bash
#
# Copyright (c) 2022 Homalozoa
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Initlize Yocto Environment
#
# Directories in Git repo
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PRJ_ROOT=$SCRIPT_PATH/..
RES_PATH=$PRJ_ROOT/resources
#
# Directories in WorkSpace
WS_ROOT=$PWD
REPO_PATH=$WS_ROOT/repos
LAYER_PATH=$WS_ROOT/layers

if ! command -v vcs &> /dev/null
then
    echo "vcstool not found, install it, please."
    return 1
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
  # link saha-layers
  ln -fs "$PRJ_ROOT/saha-layers" $WS_ROOT/repos/saha
  for file in $(ls $RES_PATH/link_*)
  do
    while IFS= read -r line; do
      ln -fs "$WS_ROOT/$line" $WS_ROOT/layers/${line##*/}
    done < $file
  done
fi

echo "Init done."
