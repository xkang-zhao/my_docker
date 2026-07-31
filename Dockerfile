ARG BASE_IMAGE=quay.io/ascend/vllm-ascend:v0.17.0rc1
FROM ${BASE_IMAGE}
ARG CLAUDE_CODE_VERSION=2.1.168

# Preserve the image's torch, transformers, torch-npu and vLLM dependency set.
# The 7B checkpoint is supplied by a read-only host mount at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl procps iproute2 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://downloads.claude.ai/claude-code-releases/bootstrap.sh \
    | bash -s -- "${CLAUDE_CODE_VERSION}"
ENV PATH="/root/.local/bin:${PATH}"
RUN claude --version

# COPY skills/ /skills/
RUN mkdir -p /workspace/deliverables /logs/agent && \
    git config --global user.email "agent@harbor-eval.local" && \
    git config --global user.name "Harbor Evaluation Agent"

WORKDIR /workspace
ENV MODEL_PATH=/models/Olmo-Hybrid-7B
ENV SERVED_MODEL_NAME=olmo-hybrid-7b
ENV VLLM_SRC=/vllm-workspace/vllm
ENV VLLM_ASCEND_SRC=/vllm-workspace/vllm-ascend
ENV WORK_DIR=/workspace
ENV DELIVERABLES_DIR=/workspace/deliverables
ENV ASCEND_VISIBLE_DEVICES=0
ENV TOKENIZERS_PARALLELISM=false
ENV IS_SANDBOX=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
