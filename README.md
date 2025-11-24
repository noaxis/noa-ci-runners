# NoaOS CI Runners - Optimized Configuration

## Overview
4台の GitHub Actions セルフホストランナー（1台ホスト直接、3台Docker）を運用し、
ラベルベースの動的負荷分散により競合を回避しながら高速CI実行を実現。

## Runner Configuration

### 1. noa-runner-1 (Host Direct)
- **Type**: ホストマシンで直接実行
- **Status**: online
- **Labels**: `[self-hosted, noa, pc, ubuntu, docker]`
- **Use case**: バックアップランナー（汎用）

### 2. noa-docker-1 (Lightweight)
- **Type**: Docker container
- **Status**: online
- **Labels**: `[self-hosted, noa, docker, light, no-redis]`
- **Use case**: Lint, type-check, complexityなど軽量ジョブ
- **Pre-installed**: uv, pytest, mypy, ruff, pre-commit, radon, task

### 3. noa-docker-2 (Heavy + Redis Primary)
- **Type**: Docker container
- **Status**: online
- **Labels**: `[self-hosted, noa, docker, heavy, redis-primary]`
- **Use case**: Redis使用ジョブ（coverage, unit tests）
- **Pre-installed**: 同上 + Redis専用割当

### 4. noa-docker-3 (Heavy + Redis Secondary)
- **Type**: Docker container
- **Status**: online
- **Labels**: `[self-hosted, noa, docker, heavy, redis-secondary]`
- **Use case**: 重量級統合テスト、STDP
- **Pre-installed**: 同上 + Redis予備割当

## Load Distribution Strategy

### Label-Based Job Assignment
```yaml
# 軽量ジョブ → noa-docker-1
runs-on: [self-hosted, noa, docker, light, no-redis]

# Redis使用ジョブ → noa-docker-2（競合回避）
runs-on: [self-hosted, noa, docker, heavy, redis-primary]

# 重量級ジョブ → noa-docker-2/3 動的分散
runs-on: [self-hosted, noa, docker, heavy]

# 汎用（全ランナー対象）
runs-on: [self-hosted, noa, docker]
```

### Conflict Avoidance
- **Redis Port (6379)**: `redis-primary` / `redis-secondary` ラベルで排他制御
- **Workspace**: Docker分離により各ランナー独立
- **I/O**: ホストの /var/run/docker.sock 共有（並列実行可能）

## Optimized Docker Image

### Base: Ubuntu 22.04
### GitHub Actions Runner: v2.330.0 (Node24 support)
### Additional Packages:
- **Python tools**: uv, pytest, pytest-cov, pytest-xdist
- **Type checking**: mypy
- **Linting**: ruff, pre-commit
- **Code quality**: radon
- **Task runner**: task (Taskfile)

### Build:
```bash
cd /home/tatsuya/noa-ci-runners
docker compose build
```

### Deploy:
```bash
docker compose down
docker compose up -d
```

## Workflow Examples

### code-quality.yml
- `detect-change-scope`: `[light]`
- `coverage`: `[heavy, redis-primary]`
- `type-check`: `[light]`
- `complexity`: `[light]`

### ci-main.yml
- `quick-checks`: `[light, no-redis]`
- `heavy-tests-unit`: `[heavy, redis-primary]`
- `heavy-tests-integration`: `[heavy, redis-secondary]`
- `all-tests-passed`: `[light]`

## Maintenance

### Token Refresh
GitHubランナー登録トークンは短命（数時間）のため、定期的な更新が必要：

```bash
# 1. 新しいトークンを取得
gh api -X POST repos/noaxis/noaos/actions/runners/registration-token --jq '.token'

# 2. .env を更新
echo "RUNNER_TOKEN=<new_token>" > /home/tatsuya/noa-ci-runners/.env

# 3. ランナーを再起動
cd /home/tatsuya/noa-ci-runners
docker compose down && docker compose up -d
```

### Health Check
```bash
# 全ランナーの状態確認
gh api repos/noaxis/noaos/actions/runners --jq '.runners[] | {name, status, busy}'

# Dockerランナーログ確認
docker logs noa-docker-runner-1
docker logs noa-docker-runner-2
docker logs noa-docker-runner-3
```

## Performance Impact

### Before Optimization:
- 単一ランナーに負荷集中
- Redis競合による実行失敗
- 依存関係の毎回インストール（2-3分）

### After Optimization:
- ✅ 4台のランナーで負荷分散
- ✅ Redis競合完全回避
- ✅ CI tools事前インストールで起動高速化
- ✅ 並列実行可能ジョブ数が4倍に増加

## Related Files
- `/home/tatsuya/noa-ci-runners/docker-compose.yml` - ランナー定義
- `/home/tatsuya/noa-ci-runners/Dockerfile` - 最適化イメージ
- `/home/tatsuya/dev/noaos/.github/workflows/` - ワークフロー定義
