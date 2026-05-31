# feature/config-environment-split 作業リスト

## 目的
開発・プレビュー・本番の設定を分離し、安全にビルド・公開できる構成へ移行する。

## やること
- [x] `config/_default` と `config/{development,preview,production}` の構成を設計。
- [x] `baseURL`、`robots`、`noindex` など環境差分パラメータを整理。
- [ ] `hugo.toml` から分割設定へ段階移行（互換維持）。
- [ ] `npm scripts` / 実行コマンドを環境別に整備。
- [ ] 環境ごとのビルド結果検証手順を README に追記。
