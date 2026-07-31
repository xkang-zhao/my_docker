FROM quay.io/ascend/vllm-ascend:v0.19.1rc1

ARG VLLM_BASE_SHA=2a69949bdadf0e8942b7a1619b229cb475beef20
ARG ASCEND_BASE_SHA=da421afad7192dac64e39ae1d32305d57344f3cf

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl jq procps && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/vllm-project/vllm.git /vllm-workspace/vllm && \
    git -C /vllm-workspace/vllm checkout "${VLLM_BASE_SHA}" && \
    git clone https://github.com/vllm-project/vllm-ascend.git \
      /vllm-workspace/vllm-ascend && \
    git -C /vllm-workspace/vllm-ascend checkout "${ASCEND_BASE_SHA}" && \
    git -C /vllm-workspace/vllm config user.name "Harbor Agent" && \
    git -C /vllm-workspace/vllm config user.email "harbor@example.com" && \
    git -C /vllm-workspace/vllm-ascend config user.name "Harbor Agent" && \
    git -C /vllm-workspace/vllm-ascend config user.email "harbor@example.com"

# COPY skills/ /skills/
WORKDIR /workspace

ENV VLLM_SRC=/vllm-workspace/vllm \
    VLLM_ASCEND_SRC=/vllm-workspace/vllm-ascend \
    MODEL_PATH=/models/DeepSeek-V4-Flash-w8a8-mtp \
    SERVED_MODEL_NAME=deepseek-v4-flash-w8a8-mtp \
    PYTORCH_NPU_ALLOC_CONF=expandable_segments:True \
    OMP_PROC_BIND=false \
    OMP_NUM_THREADS=1
