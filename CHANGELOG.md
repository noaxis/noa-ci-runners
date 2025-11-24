# NoaOS CI Runners - Changelog

## 2025-11-24 - Python 3.12 Custom Image

### Changes
カスタムDockerイメージを構築し、Python 3.12を事前インストール。

### Before
- ベースイメージ: `myoung34/github-runner:latest` (Ubuntu 20.04 + Python 3.8)
- Python 3.12: `actions/setup-python@v6` が毎回インストール（2-3分）
- CI tools: 事前インストール済み

### After
- ベースイメージ: カスタムビルド (Ubuntu 22.04 + Python 3.12.12)
- Python 3.12: **事前インストール済み（0秒）**
- CI tools: **事前インストール済み**
- GitHub Actions Runner: **v2.321.0統合**

### Files Updated
```
/home/tatsuya/noa-ci-runners/
├── Dockerfile          # Ubuntu 22.04 + Python 3.12 + Runner
├── entrypoint.sh       # 自動登録スクリプト（--ephemeral削除、永続化）
├── docker-compose.yml  # カスタムイメージ使用（変更なし）
├── README.md           # ドキュメント
└── CHANGELOG.md        # このファイル
```

### ⚠️ 注意: ephemeralフラグ削除
初期実装では `--ephemeral` フラグを使用していましたが、ジョブ完了後の自動登録解除により不安定になったため削除しました。現在は永続的なランナーとして動作します。

### Verification
```bash
$ docker exec noa-docker-runner-2 python3 --version
Python 3.12.12

$ docker exec noa-docker-runner-2 which pytest mypy ruff task
/usr/local/bin/pytest
/usr/local/bin/mypy
/usr/local/bin/ruff
/usr/local/bin/task
```

### Performance Impact
**CI起動時間（推定）:**
- Before: Python 3.12インストール 2-3分 + ジョブ実行
- After: **ジョブ実行のみ**（2-3分短縮）

**並列実行時の効果:**
- 4ジョブ同時実行 → **合計 8-12分の時間短縮**

### Build Command
```bash
cd /home/tatsuya/noa-ci-runners
docker compose build
docker compose up -d
```

### Image Size
```
noaos-ci-runner:latest  ~1.5GB
```

### Related PR
https://github.com/noaxis/noaos/pull/1225
