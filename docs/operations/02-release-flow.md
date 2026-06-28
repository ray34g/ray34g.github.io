# 公開フロー（preview -> production）

## フロー図

```text
feature branch
  -> PR作成
  -> preview build
  -> preview URLレビュー
  -> 承認
  -> main/developへマージ
  -> production build
  -> deploy
```

## 手順
1. 作業ブランチで実装しPRを作成。
2. preview環境で成果を確認（noindex前提）。
3. レビューチェックリストを満たしたら承認。
4. production ビルド後にデプロイ。

## 注意点
- previewとproductionで `baseURL` と `robots` を混在させない。
- 本番反映は承認コメントを残してから実施する。
