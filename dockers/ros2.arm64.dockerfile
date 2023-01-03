# Copyright (c) 2022 Homalozoa
# Author: Homalozoa nx.tardis@gmail.com
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

FROM arm64v8/ubuntu:22.04
LABEL org.opencontainers.image.authors=nx.tardis@gmail.com

ENV UBUNTU_VER=jammy
ENV ROS_VER=humble

# replace mirror (replace one near you)
RUN apt-get update && \
  apt-get install -q -y --no-install-recommends ca-certificates && \
  mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ ${UBUNTU_VER} main restricted universe multiverse\n" > /etc/apt/sources.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ ${UBUNTU_VER}-updates main restricted universe multiverse\n" >> /etc/apt/sources.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ ${UBUNTU_VER}-backports main restricted universe multiverse\n" >> /etc/apt/sources.list && \
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ ${UBUNTU_VER}-security main restricted universe multiverse" >> /etc/apt/sources.list

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
  ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
  apt-get update && \
  apt-get install -q -y --no-install-recommends tzdata apt-utils

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
  bash-completion \
  dirmngr \
  gnupg2 \
  lsb-release \
  python3-pip

# setup ros2 sources.list (replace one near you)
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ros2/ubuntu/ ${UBUNTU_VER} main" > /etc/apt/sources.list.d/ros2-latest.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# install ros2
RUN apt-get update && \
  apt-get install -q -y --no-install-recommends \
  build-essential \
  cmake \
  git \
  python3-colcon-common-extensions \
  python3-flake8 \
  python3-pip \
  python3-pytest-cov \
  python3-rosdep \
  python3-setuptools \
  python3-vcstool \
  wget \
  curl \
  vim \
  ros-${ROS_VER}-ros-base \
  ros-${ROS_VER}-rmw-fastrtps-cpp

# set python3 default
RUN rm -f /usr/bin/python && \
  ln -s /usr/bin/python3 /usr/bin/python

# change pip mirror (replace one near you)
RUN pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# install some pip packages needed for testing
RUN python3 -m pip install -U \
  flake8-blind-except \
  flake8-builtins \
  flake8-class-newline \
  flake8-comprehensions \
  flake8-deprecated \
  flake8-docstrings \
  flake8-import-order \
  flake8-quotes \
  pytest-repeat \
  pytest-rerunfailures \
  pytest \
  setuptools

# remove cache
RUN apt-get clean

# setup entrypoint
RUN echo '#!/bin/bash\n' > /ros_entrypoint.sh && \
  echo 'set -e\n' >> /ros_entrypoint.sh && \
  echo '# setup ros2 environment\n' >> /ros_entrypoint.sh && \
  echo 'source /opt/ros/${ROS_VER}/setup.sh\n' >> /ros_entrypoint.sh && \
  echo 'export RMW_IMPLEMENTATION=rmw_fastrtps_cpp\n' >> /ros_entrypoint.sh && \
  echo 'exec "$@"' >> /ros_entrypoint.sh && \
  chmod +x /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
