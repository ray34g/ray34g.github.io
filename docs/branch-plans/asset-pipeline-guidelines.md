# Asset Pipeline Guidelines

## CSS構造
- エントリは `assets/css/style.css` を使用。
- 以下4レイヤで分割する。
  - `base`: reset, token, typography
  - `layout`: header/footer/grid
  - `components`: 再利用UI部品
  - `features`: ページ固有表現

## JS構造
- `assets/js` に機能単位で配置。
- 例:
  - `header.js`: ナビ・スクロール連動
  - `search.js`: クライアント検索
  - `ui.js`: 汎用補助処理

## アイコン方針
- 現在: Font Awesome併用。
- 目標: SVG spriteを主軸に移行し、ブランド/一般アイコンを分離。
- ルール:
  - UI共通アイコンは `assets/icons/ui/`。
  - ブランドアイコンは `assets/icons/brand/`。
  - 装飾用途はCSS backgroundへ寄せる。

## フォント方針
- 現在: 外部配信 + `assets/webfonts`。
- 目標: サブセット化してLCP/CLSを改善。
- ルール:
  - 日本語本文は必要文字のみのsubsetを生成。
  - `font-display: swap` を前提。
  - ウェイト数は最小化（通常2ウェイト）。

## Lighthouse改善対象
- Performance: 未使用CSS/JS削減、画像最適化、フォント最適化。
- Accessibility: コントラストとラベル整備。
- Best Practices: 3rd-party scriptの整理。
- SEO: canonical/hreflang/metadata一貫性。
