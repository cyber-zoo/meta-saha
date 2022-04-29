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
#
WS_ROOT=$PWD
REPO_PATH=$WS_ROOT/repos
LAYER_PATH=$WS_ROOT/layers
BUILD_PATH=$WS_ROOT/build
#
echo "Clear all building files"
echo "Removing layers"
rm -rf $LAYER_PATH
echo "Removing repos"
rm -rf $REPO_PATH
echo "Removing build"
rm -rf $BUILD_PATH
