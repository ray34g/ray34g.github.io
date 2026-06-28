# 差分マップ: givingmachine-jp-website -> ray34g.github.io

## 対象
- 比較元: `../givingmachine-jp-website`
- 取り込み先: 本リポジトリ

## 構成差分（主要）
- `config`
  - givingmachine: `_default` + `development` + `preview` + `production` の環境分離。
  - portfolio: `_default/*.toml` 中心で環境分離は未導入。
- `layouts`
  - givingmachine: ページ種別ディレクトリと `partials/*` の細分化が進んでいる。
  - portfolio: `_default` と `partials` が中心で、責務分割の余地あり。
- `assets`
  - givingmachine: `css/base|components|features|layout`, `js`, `icons`, `fonts` が分離。
  - portfolio: `css/vendor` と画像/フォント中心で、構造の抽象化余地あり。
- `content/data/i18n`
  - givingmachine: `data` と `i18n` を活用した運用前提。
  - portfolio: 言語設定はあるが `data` 駆動の拡張余地あり。
- CI/運用
  - givingmachine: `ci/scripts/build_pages.sh` と `verify_pages.sh`、運用 docs が充実。
  - portfolio: CI検証と運用手順の明文化を強化可能。

## 取り込み分類

### 即移植
- 環境別設定ディレクトリ構成（`config/{development,preview,production}`）。
- partial の命名/分割ルール。
- build/verify の2段階検証フロー。

### 要調整
- フォントサブセット化（利用フォント・日本語範囲に合わせる必要）。
- icon基盤（既存資産と整合する統合方式の選定が必要）。
- Studio/Preview の分離運用（公開基盤差分の吸収が必要）。

### 見送り（現時点）
- GivingMachine固有の運用前提に依存した公開同期スクリプト。
- 組織向け運用ドキュメントの固有手順。

## 次アクション
1. `feature/config-environment-split` で環境分離を先行導入。
2. `feature/layout-partials-architecture` でテンプレート責務を整理。
3. `feature/ci-quality-gates` で build/verify を再現。
