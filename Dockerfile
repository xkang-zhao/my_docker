# 1. 使用 NVIDIA 官方的 NGC 基础镜像（绕过 Docker Hub）
# FROM nvidia/cuda:12.8.1-base-ubuntu20.04
FROM nvcr.io/nvidia/cuda:12.8.1-base-ubuntu20.04

# 2. 静默安装设置
ENV DEBIAN_FRONTEND=noninteractive

# 3. 合并安装基础工具、SSH 服务、Python 包管理工具及编译依赖 (减少镜像层数)
RUN apt-get update && apt-get install -y \
    wget \
    git \
    vim \
    cmake \
    ca-certificates \
    openssh-client \
    openssh-server \
    python3-pip \
    python3-dev \
    build-essential \
    pkg-config \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    libavfilter-dev \
    libopengl0 \
    libegl1 \
    libglx-mesa0 \
    && rm -rf /var/lib/apt/lists/*

# 配置 SSH 密钥和登录权限
RUN mkdir -p /var/run/sshd && \
    /usr/bin/ssh-keygen -A && \
    sed -i 's/^#\?StrictHostKeyChecking.*/    StrictHostKeyChecking no/' /etc/ssh/ssh_config && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# 安装 jupyterlab
RUN pip3 install jupyterlab==3.2.5

# 下载并配置 Jupyter
RUN mkdir -p /home/inspur/image_components/jupyter_configure /etc/jupyter && \
    wget -P /home/inspur/image_components/jupyter_configure https://raw.githubusercontent.com/Winowang/jupyter_gpu/master/jupyter_notebook_config.py && \
    wget -P /home/inspur/image_components/jupyter_configure https://raw.githubusercontent.com/Winowang/jupyter_gpu/master/custom.js && \
    cp -rf /home/inspur/image_components/jupyter_configure/* /etc/jupyter 

RUN echo "c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}" >> /etc/jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" >> /etc/jupyter/jupyter_notebook_config.py


# 4. 安装 Miniconda (这是管理 Python 环境的最佳方式)
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 5. 配置 Conda 环境变量 (这一步非常重要)
ENV PATH=/opt/conda/bin:$PATH
ENV SHELL=/bin/bash

# 初始化 bash (让 conda activate 命令可用)
RUN conda init bash

# 接受 Conda 服务条款，并配置不提示（可选但推荐在 docker 中使用）
RUN conda config --set always_yes yes && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# 6. 设置工作目录 (建议不要使用 /root，使用 /workspace 更标准)
WORKDIR /root

RUN conda install -n base ipykernel 

# 7. git rlinf
RUN git clone https://github.com/RLinf/RLinf.git

# 8. 安装isaaclab的环境，本地安装
RUN cd /root/RLinf && \
    bash requirements/install.sh embodied --model gr00t --env isaaclab

# 10. 默认命令：后台启动 sshd 服务，并在前台运行 Jupyter Lab
CMD ["/bin/bash", "-c", "/usr/sbin/sshd && jupyter lab --ip=0.0.0.0 --no-browser --allow-root"]
