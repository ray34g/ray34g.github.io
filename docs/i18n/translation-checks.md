# 翻訳漏れチェック設計

## 方針
- すべての `i18n_key` 参照が `i18n/ja.toml` と `i18n/en.toml` に存在することを検証する。
- 新規キー追加時は2言語同時更新を原則化する。

## ルール
- `data/**/*.toml` の `i18n_key` を抽出。
- `i18n/ja.toml` / `i18n/en.toml` のキー一覧と突合。
- 欠損キーがあれば CI で失敗させる。

## 実装メモ
- 初期実装は shell + `rg` で十分。
- 将来的に `scripts/check_i18n_keys.sh` を追加してCIに統合する。
