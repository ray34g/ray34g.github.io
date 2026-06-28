# Studio/Preview Workflow Adoption

## 調査サマリー（givingmachine-jp-studio）
- 単一リポジトリ内で `website` / `website-preview` / `website-main` を分離し、用途ごとにビルド対象を切り替えている。
- `scripts/build-main.sh`, `scripts/build-preview.sh`, `scripts/build-release.sh`, `scripts/build-public.sh` により、公開目的別の出力を使い分けている。
- `public/main` と `public/release` を分け、レビュー用と公開用の成果物を論理的に分離している。
- `static/admin` と Decap CMS 資産により編集導線を別管理している。

## 本リポジトリへの適用方針
- リポジトリは分割せず、環境分離（`config/development|preview|production`）で吸収する。
- CIでは `preview` と `production` のビルドを明示的に分離する。
- `preview` は noindex 前提、`production` は index 前提に固定する。
- 変更レビューは preview URL を正本とし、production反映は承認後のみ実施する。

## 推奨ブランチ運用
1. 作業ブランチで変更作成
2. PR作成で preview build 実行
3. preview URL でレビュー
4. 承認後に main/develop へマージ
5. production build/deploy 実行

## 成果物分離ルール
- Preview成果物: `public-preview/`（CI一時成果物）
- Production成果物: `public/`（公開成果物）
- レポート類: `public/reports/` 配下に隔離
