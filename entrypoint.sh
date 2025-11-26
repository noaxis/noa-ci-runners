#!/bin/bash
set -e

# 環境変数の検証
: "${REPO_URL:?REPO_URL must be set}"
: "${RUNNER_TOKEN:?RUNNER_TOKEN must be set}"
: "${RUNNER_NAME:?RUNNER_NAME must be set}"

# デフォルト値
RUNNER_WORKDIR=${RUNNER_WORKDIR:-_work}
LABELS=${LABELS:-self-hosted,linux,x64}
RUNNER_GROUP=${RUNNER_GROUP:-default}

cd /actions-runner

# 古い設定を削除（競合防止）
if [ -f ".runner" ]; then
    echo "Removing old runner configuration..."
    ./config.sh remove --token "${RUNNER_TOKEN}" 2>/dev/null || true
    rm -f .runner .credentials .credentials_rsaparams
fi

# 常に再登録（--replaceで既存セッションを置き換え）
echo "Configuring GitHub Actions Runner..."
./config.sh \
    --unattended \
    --url "${REPO_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${LABELS}" \
    --runnergroup "${RUNNER_GROUP}" \
    --replace

# クリーンアップハンドラ（SIGTERM/SIGINT対応）
cleanup() {
    echo "Graceful shutdown: removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}" 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT EXIT

# ランナー起動
echo "Starting runner..."
exec "$@"
