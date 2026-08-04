ARG BASE_IMAGE=quay.io/ascend/vllm-ascend:v0.19.1rc1-a3
FROM ${BASE_IMAGE}

ARG VLLM_BASE_SHA=b1388b1fbf5aaef47937fabe98931211684666a6
ARG ASCEND_BASE_SHA=da421afad7192dac64e39ae1d32305d57344f3cf
ARG CLAUDE_CODE_VERSION=2.1.168

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git curl jq procps iproute2 \
    && rm -rf /var/lib/apt/lists/*

# The vllm-ascend base image already contains both source repositories. Reuse
# those worktrees instead of cloning into their existing, non-empty paths.
RUN test -d /vllm-workspace/vllm/.git && \
    test -d /vllm-workspace/vllm-ascend/.git && \
    git -C /vllm-workspace/vllm cat-file -e "${VLLM_BASE_SHA}^{commit}" && \
    git -C /vllm-workspace/vllm-ascend cat-file -e "${ASCEND_BASE_SHA}^{commit}" && \
    git -C /vllm-workspace/vllm checkout --detach "${VLLM_BASE_SHA}" && \
    git -C /vllm-workspace/vllm-ascend checkout --detach "${ASCEND_BASE_SHA}" && \
    test "$(git -C /vllm-workspace/vllm rev-parse HEAD)" = "${VLLM_BASE_SHA}" && \
    test "$(git -C /vllm-workspace/vllm-ascend rev-parse HEAD)" = "${ASCEND_BASE_SHA}" && \
    git -C /vllm-workspace/vllm config user.name "Harbor Agent" && \
    git -C /vllm-workspace/vllm config user.email "harbor@example.com" && \
    git -C /vllm-workspace/vllm-ascend config user.name "Harbor Agent" && \
    git -C /vllm-workspace/vllm-ascend config user.email "harbor@example.com"

RUN curl -fsSL https://downloads.claude.ai/claude-code-releases/bootstrap.sh \
    | bash -s -- "${CLAUDE_CODE_VERSION}"
ENV PATH="/root/.local/bin:${PATH}"
RUN claude --version

# COPY skills/ /skills/
RUN mkdir -p /workspace/deliverables /logs/agent
WORKDIR /workspace

ENV VLLM_SRC=/vllm-workspace/vllm \
    VLLM_ASCEND_SRC=/vllm-workspace/vllm-ascend \
    MODEL_PATH=/models/DeepSeek-V4-Flash-w8a8-mtp \
    SERVED_MODEL_NAME=deepseek-v4-flash-w8a8-mtp \
    PYTORCH_NPU_ALLOC_CONF=expandable_segments:True \
    OMP_PROC_BIND=false \
    OMP_NUM_THREADS=1 \
    TOKENIZERS_PARALLELISM=false \
    IS_SANDBOX=1 \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
