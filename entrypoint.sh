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

# 既存の設定ファイルを強制削除（コンテナ再起動時）
if [ -f ".runner" ]; then
    echo "Removing existing runner configuration files..."
    rm -f .runner .credentials .credentials_rsaparams || true
fi

# ランナーの登録
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

# クリーンアップハンドラ
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}" || true
}
trap cleanup EXIT

# ランナー起動
echo "Starting runner..."
exec "$@"
