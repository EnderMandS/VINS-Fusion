FROM ros:kinetic-ros-base-xenial

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO kinetic
ARG USERNAME=m
ARG PROJECT_NAME=vinsfusion

RUN   apt update &&  \
      apt install -y vim tree wget curl git unzip ninja-build && \
      apt install -y zsh && \
      apt install -y libatlas-base-dev libeigen3-dev libgoogle-glog-dev libsuitesparse-dev python-catkin-tools && \
      apt install -y ros-${ROS_DISTRO}-cv-bridge  ros-${ROS_DISTRO}-image-transport  ros-${ROS_DISTRO}-message-filters \
            ros-${ROS_DISTRO}-tf && \
      DEBIAN_FRONTEND=noninteractive apt install -y keyboard-configuration && \
      rm -rf /var/lib/apt/lists/*

# Build and install Ceres
ENV CERES_VERSION="1.12.0"
WORKDIR /home/${USERNAME}/pkg/ceres
RUN   git clone https://ceres-solver.googlesource.com/ceres-solver && \
      cd ceres-solver && git checkout tags/${CERES_VERSION} && mkdir build && cd build && \
      cmake -GNinja .. && ninja && ninja install && ninja clean

# setup user
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID ${USERNAME} \
    && useradd --uid $USER_UID --gid $USER_GID -m ${USERNAME} \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}
USER ${USERNAME}

# install zsh & set zsh as the default shell
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' /home/${USERNAME}/.zshrc
SHELL ["/bin/zsh", "-c"]

WORKDIR /home/${USERNAME}/code/ros_ws
RUN   git clone --depth 1 --recursive https://github.com/HKUST-Aerial-Robotics/VINS-Fusion.git src && \
      chmod 777 -R /home/${USERNAME}/code/ros_ws && . /opt/ros/${ROS_DISTRO}/setup.sh && \
      catkin_make -DCATKIN_WHITELIST_PACKAGES="" -DCMAKE_BUILD_TYPE=Release && \
      echo "source /home/m/code/ros_ws/devel/setup.zsh" >> /home/${USERNAME}/.zshrc

WORKDIR /home/${USERNAME}/code/ros_ws/src

ENTRYPOINT [ "/bin/zsh" ]
# ENTRYPOINT [ "/home/m/code/ros_ws/setup.zsh" ]
