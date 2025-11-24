# NoaOS CI専用カスタムランナー
# Ubuntu 22.04 + Python 3.12 + GitHub Actions Runner + CI tools

FROM ubuntu:22.04

# 環境変数
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_ALLOW_RUNASROOT=1
ENV GITHUB_ACTIONS_RUNNER_VERSION=2.330.0

# 基本パッケージとPython 3.12
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    curl \
    wget \
    git \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    sudo \
    ca-certificates \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Python 3.12をデフォルトに設定
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --set python3 /usr/bin/python3.12 \
    && ln -sf /usr/bin/python3.12 /usr/bin/python

# pip最新化
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

# CI用ツールを事前インストール
RUN python3.12 -m pip install --no-cache-dir \
    uv \
    pytest \
    pytest-cov \
    pytest-xdist \
    mypy \
    ruff \
    pre-commit \
    radon \
    types-PyYAML \
    types-requests

# Task runner のインストール
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# GitHub Actions Runnerのダウンロードとインストール
RUN mkdir -p /actions-runner && cd /actions-runner \
    && curl -o actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz \
       -L https://github.com/actions/runner/releases/download/v${GITHUB_ACTIONS_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh

WORKDIR /actions-runner

# Entrypointスクリプト
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run"]
