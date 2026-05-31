# セットアップ手順

## 初回構築
1. リポジトリを取得する。
2. 必要ツールを確認する（`hugo`, `git`, `bash`, `rg`）。
3. 開発サーバーを起動する。

```bash
hugo server --environment development
```

## 更新手順
1. 最新変更を取り込む。
2. 差分に応じて `config`, `layouts`, `assets`, `content` を確認する。
3. ローカルで build/verify を実行する。

```bash
./ci/scripts/build_pages.sh public
./ci/scripts/verify_pages.sh public
```

## トラブル時の基本切り分け
1. `hugo` が使えるか確認する。
2. `config/<environment>` の設定値を確認する。
3. `layouts` 変更がある場合は partial 参照名の整合を確認する。
4. `verify_pages.sh` の失敗ログを先に潰す。
