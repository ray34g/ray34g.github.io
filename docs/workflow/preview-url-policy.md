# Preview URL Policy

## URL命名
- 推奨形式: `https://preview-<branch-or-pr>.ray34g.com/`
- 長期固定が必要な場合: `https://preview.ray34g.com/<ticket-id>/`

## 公開期間
- 既定: マージ後 14日で削除
- 長期レビュー案件: 最大 60日（要明示申請）

## アクセス制御
- 最低限: `noindex,nofollow` + robots disallow
- 推奨: Basic認証またはIP許可（機密情報がある場合は必須）

## 必須メタ
- `<meta name="robots" content="noindex, nofollow">`
- canonical は production URL を参照しない（preview URL 自己参照）
- フッター等に preview 表示ラベルを出す
