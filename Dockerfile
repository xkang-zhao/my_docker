FROM quay.io/ascend/vllm-ascend:v0.14.0rc1-a3

# ============================================================
# System dependencies (Claude Code requires procps for process management)
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Pre-install Claude Code (no download needed during air-gapped evaluation)
# ============================================================
RUN curl -fsSL https://downloads.claude.ai/claude-code-releases/bootstrap.sh | bash

# Verify installation
ENV PATH="/root/.local/bin:$PATH"
RUN claude --version

# ============================================================
# Additional verification tools
# ============================================================
RUN pip install --no-cache-dir \
    pyyaml \
    requests \
    pillow

# ============================================================
# Prepare working directories
# ============================================================
RUN mkdir -p /workspace/deliverables /workspace/repo

# ============================================================
# Initialize delivery git repository
# ============================================================
WORKDIR /workspace/repo
RUN git init && \
    git config user.email "agent@harbor-eval.local" && \
    git config user.name "Harbor Evaluation Agent"

# Copy vllm-ascend source into the repo as initial state
# Agent changes will be committed to this repo
RUN cp -r /vllm-workspace/vllm-ascend/* . && \
    git add -A && \
    git commit -m "chore: initial state from vllm-ascend base image"

WORKDIR /workspace

# ============================================================
# Environment variables (overrideable at runtime via Harbor --ae)
# ============================================================
ENV MODEL_PATH=/models/DeepSeek-OCR-2
ENV MODEL_NAME=DeepSeek-OCR-2
ENV SERVED_MODEL_NAME=deepseek-ocr-2
ENV VLLM_SRC=/vllm-workspace/vllm
ENV VLLM_ASCEND_SRC=/vllm-workspace/vllm-ascend
ENV WORK_DIR=/workspace
ENV DELIVERABLES_DIR=/workspace/deliverables
ENV VLLM_ASCEND_TP_SIZE=1

# Claude Code requires these to run inside containers (sandbox mode)
ENV IS_SANDBOX=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
