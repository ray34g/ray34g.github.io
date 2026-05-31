# feature/layout-partials-architecture 作業リスト

## 目的
レイアウトを責務分離して再利用性と保守性を上げる。

## やること
- [ ] 既存テンプレートをヘッダー/フッター/メニュー/SEO/セクション単位で分解。
- [ ] `layouts/partials` の命名規約と配置ルールを定義。
- [ ] 汎用セクション（hero/card/cta/article-list）を partial 化。
- [ ] ページ種別ごとの `block` 設計（`baseof` 依存を最適化）。
- [ ] レンダリング重複を削減し、差分が最小になるようテンプレート整理。
