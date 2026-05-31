# 実装順ロードマップ

## 方針
- 先に土台（調査・設定分離・テンプレート構造）を固める。
- 次に横断機能（アセット・多言語/データ）を入れる。
- その後に品質ゲート・運用整備を行い、最後にテーマ化で抽象化する。

## 着手順（推奨）
1. `feature/audit-architecture`
2. `feature/config-environment-split`
3. `feature/layout-partials-architecture`
4. `feature/asset-pipeline-structure`
5. `feature/i18n-and-data-driven-content`
6. `feature/ci-quality-gates`
7. `feature/studio-preview-workflow`
8. `feature/docs-operations-playbook`
9. `feature/theme-extract-distribution`

## 依存関係
- `config-environment-split` は `audit-architecture` 完了後に着手。
- `layout-partials-architecture` は `audit-architecture` 完了後に着手。
- `asset-pipeline-structure` は `layout-partials-architecture` に追従。
- `i18n-and-data-driven-content` は `layout-partials-architecture` と並行可能だが、マージは後。
- `ci-quality-gates` は `config-environment-split` と主要テンプレート変更完了後に導入。
- `studio-preview-workflow` は `config-environment-split` 後が安全。
- `docs-operations-playbook` は各ブランチ成果の確定後に更新。
- `theme-extract-distribution` は全ブランチの成果を取り込んだ最後の統合作業。

## マージ順（推奨）
1. `feature/audit-architecture`
2. `feature/config-environment-split`
3. `feature/layout-partials-architecture`
4. `feature/asset-pipeline-structure`
5. `feature/i18n-and-data-driven-content`
6. `feature/ci-quality-gates`
7. `feature/studio-preview-workflow`
8. `feature/docs-operations-playbook`
9. `feature/theme-extract-distribution`
