# 1. 使用 NVIDIA 官方的基础镜像
FROM nvidia/cuda:12.8.1-base-ubuntu22.04

# 2. 静默安装设置
ENV DEBIAN_FRONTEND=noninteractive

# 3. 合并安装基础工具 (减少镜像层数)
RUN apt-get update && apt-get install -y \
    wget \
    git \
    vim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 新增：安装 gcc 和编译必需的 Linux 头文件
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc build-essential linux-libc-dev && \
    rm -rf /var/lib/apt/lists/*

# 4. 安装 Miniconda (这是管理 Python 环境的最佳方式)
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 5. 配置 Conda 环境变量 (这一步非常重要)
ENV PATH=/opt/conda/bin:$PATH

# 初始化 bash (让 conda activate 命令可用)
RUN conda init bash

# 接受 Conda 服务条款
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# 6. 设置工作目录 (建议不要使用 /root，使用 /workspace 更标准)
WORKDIR /root

# 7. 安装lerobot环境
RUN conda create -y -n lerobot python=3.10 
RUN conda run -n lerobot conda install -y ffmpeg -c conda-forge
RUN conda run -n lerobot pip install lerobot --no-cache-dir
RUN conda clean -a -y

# 7. 验证安装 (使用 conda run 验证环境中真实的 python 版本)
RUN conda --version && conda run -n lerobot python --version

# 8. 默认命令

CMD ["/bin/bash"]
