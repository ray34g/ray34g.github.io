# partials 命名規約と配置ルール

## 配置方針
- エントリ partial は `layouts/partials/*.html`（例: `head.html`, `header.html`）。
- 詳細 partial は責務単位でサブディレクトリに配置（例: `partials/head/meta.html`）。
- 1 partial = 1責務を原則にし、複数責務は分割。

## 命名規約
- ファイル名は kebab-case。
- 役割が明確な語を優先（`meta`, `assets`, `icons`, `vendor`, `nav`）。
- コンポーネント固有処理は `components` ではなく、親責務配下に置く（例: `header/nav.html`）。

## 分割の優先順
1. `head`（SEO/asset/icon）
2. `header`（brand/toggle/nav）
3. `footer`（情報表示）
4. `scripts`（vendor/page-behavior）

## 次フェーズ
- `sections` 用 partial 群（hero/card/cta/article-list）を追加。
- メニュー定義を `data` 化し `header/nav.html` から参照する。
