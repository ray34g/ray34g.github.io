# 本番反映前レビュー チェックリスト

- [ ] 主要ページ（home, ja, en）が preview で表示される
- [ ] 主要導線リンクが 404 にならない
- [ ] 言語切替リンク（ja/en）が相互到達できる
- [ ] title/description/canonical/hreflang が意図通り
- [ ] preview 環境で `noindex,nofollow` が有効
- [ ] 画像の欠損・崩れがない
- [ ] モバイル表示でヘッダー/メニュー崩れがない
- [ ] CI `build_pages` / `verify_pages` が成功
- [ ] Lighthouse結果を確認（blockingではないが劣化確認）
- [ ] 承認者が production反映可否を明示
