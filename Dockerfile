# 1. 使用 NVIDIA 官方的基础镜像
FROM nvidia/cuda:12.8.1-base-ubuntu20.04

# 2. 静默安装设置
ENV DEBIAN_FRONTEND=noninteractive

# 3. 合并安装基础工具、SSH 服务、Python 包管理工具及编译依赖 (减少镜像层数)
RUN apt-get update && apt-get install -y \
    wget \
    git \
    vim \
    ca-certificates \
    openssh-client \
    openssh-server \
    python3-pip \
    gcc \
    python3-dev \
    linux-libc-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置 SSH 密钥和登录权限
RUN mkdir -p /var/run/sshd && \
    /usr/bin/ssh-keygen -A && \
    sed -i 's/^#\?StrictHostKeyChecking.*/    StrictHostKeyChecking no/' /etc/ssh/ssh_config && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# 安装 jupyterlab
RUN pip3 install jupyterlab==3.2.5

# 注意：诸如 /usr/sbin/sshd 和 jupyter lab 等长期运行的命令不能直接写在 Dockerfile 的编译流程中，
# 建议通过 CMD、ENTRYPOINT 或是进入运行后的容器内部手动执行。
# CMD ["/bin/bash", "-c", "/usr/sbin/sshd && jupyter lab --ip=0.0.0.0 --no-browser --allow-root"]

# 下载并配置 Jupyter
RUN mkdir -p /home/inspur/image_components/jupyter_configure /etc/jupyter && \
    wget -P /home/inspur/image_components/jupyter_configure https://raw.githubusercontent.com/Winowang/jupyter_gpu/master/jupyter_notebook_config.py && \
    wget -P /home/inspur/image_components/jupyter_configure https://raw.githubusercontent.com/Winowang/jupyter_gpu/master/custom.js && \
    cp -rf /home/inspur/image_components/jupyter_configure/* /etc/jupyter


# 4. 安装 Miniconda (这是管理 Python 环境的最佳方式)
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 5. 配置 Conda 环境变量 (这一步非常重要)
ENV PATH=/opt/conda/bin:$PATH

# 初始化 bash (让 conda activate 命令可用)
RUN conda init bash

# 接受 Conda 服务条款，并配置不提示（可选但推荐在 docker 中使用）
RUN conda config --set always_yes yes && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# 6. 设置工作目录 (建议不要使用 /root，使用 /workspace 更标准)
WORKDIR /root

# 7. 安装lerobot环境与Jupyter内核支持
RUN conda create -y -n lerobot python=3.10 
RUN conda run -n lerobot conda install -y ffmpeg -c conda-forge
RUN conda run -n lerobot pip install lerobot ipykernel --no-cache-dir

RUN conda clean -a -y

# 8. 验证安装 (使用 conda run 验证环境中真实的 python 版本)
RUN conda --version && conda run -n lerobot python --version

# 8. 默认命令：后台启动 sshd 服务，并在前台运行 Jupyter Lab
CMD ["/bin/bash", "-c", "/usr/sbin/sshd && jupyter lab --ip=0.0.0.0 --no-browser --allow-root"]
