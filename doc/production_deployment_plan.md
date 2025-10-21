# 会員レベル変更申請システム 本番デプロイ計画書

## デプロイ概要

### 変更内容
- 即座のレベル変更から申請ベースのシステムに変更
- 申請は翌月1日に自動実行
- 申請管理機能の追加
- エラーハンドリングと通知機能の実装

### 影響範囲
- 管理者のレベル変更操作
- ユーザー詳細・編集画面
- インセンティブ計算（影響なし - 履歴ベース計算継続）

## デプロイ前準備

### 1. バックアップ作成

#### データベースバックアップ
```bash
# 本番データベースのバックアップ
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# 重要テーブルの個別バックアップ
pg_dump $DATABASE_URL -t users > users_backup_$(date +%Y%m%d_%H%M%S).sql
pg_dump $DATABASE_URL -t user_level_histories > histories_backup_$(date +%Y%m%d_%H%M%S).sql
```

#### アプリケーションコードのバックアップ
```bash
# 現在のリリースタグを記録
git tag production-backup-$(date +%Y%m%d_%H%M%S)
git push origin --tags
```

### 2. 環境変数の確認
```bash
# 必要な環境変数が設定されていることを確認
echo $DATABASE_URL
echo $RAILS_ENV
echo $SECRET_KEY_BASE
```

### 3. 依存関係の確認
- Ruby 3.2.2
- Rails 8.0.2
- PostgreSQL（本番環境）
- Active Job（バックグラウンドジョブ）

## デプロイ手順

### Phase 1: データベースマイグレーション

#### 1. メンテナンスモード開始
```bash
# Herokuの場合
heroku maintenance:on -a your-app-name

# その他の環境では適切なメンテナンス手順を実行
```

#### 2. マイグレーション実行
```bash
# マイグレーションの実行
rails db:migrate

# マイグレーション結果の確認
rails db:migrate:status
```

#### 3. データ整合性確認
```bash
# Railsコンソールで確認
rails console

# 新しいテーブルが作成されていることを確認
LevelChangeApplication.count
# => 0 (初期状態)

# 既存データの整合性確認
User.joins(:level).count
UserLevelHistory.count
```

### Phase 2: アプリケーションデプロイ

#### 1. コードデプロイ
```bash
# Herokuの場合
git push heroku main

# その他の環境では適切なデプロイ手順を実行
```

#### 2. アプリケーション起動確認
```bash
# ヘルスチェック
curl https://your-app.com/up

# 管理画面アクセス確認
curl -I https://your-app.com/admin
```

#### 3. 新機能の動作確認
```bash
# Railsコンソールで基本動作確認
rails console

# 申請作成テスト（管理者権限で）
admin = User.find_by(admin: true)
test_user = User.first
# 実際の申請作成は管理画面で実行
```

### Phase 3: スケジューラー設定

#### 1. cron設定（Herokuの場合はScheduler）
```bash
# Heroku Schedulerの設定
heroku addons:create scheduler:standard -a your-app-name
heroku addons:open scheduler -a your-app-name

# 以下のコマンドを毎月1日0:00に設定
rake level_change:execute
```

#### 2. 初回実行テスト
```bash
# 手動でバッチジョブをテスト実行
heroku run rake level_change:execute -a your-app-name

# ログ確認
heroku logs --tail -a your-app-name
```

### Phase 4: メンテナンスモード解除

#### 1. 最終動作確認
- 管理画面へのアクセス
- ユーザー詳細画面の表示
- 申請管理画面の表示

#### 2. メンテナンスモード解除
```bash
# Herokuの場合
heroku maintenance:off -a your-app-name
```

## デプロイ後の確認事項

### 1. 機能確認チェックリスト

- [ ] 管理画面にアクセスできる
- [ ] ユーザー一覧が正常に表示される
- [ ] ユーザー詳細画面が正常に表示される
- [ ] ユーザー編集画面でレベル変更申請ができる
- [ ] 申請管理画面が正常に表示される
- [ ] 申請詳細画面が正常に表示される
- [ ] 申請キャンセル機能が動作する
- [ ] インセンティブ計算が正常に動作する

### 2. パフォーマンス確認

#### レスポンス時間測定
```bash
# 主要画面のレスポンス時間確認
curl -w "@curl-format.txt" -o /dev/null -s https://your-app.com/admin/users
curl -w "@curl-format.txt" -o /dev/null -s https://your-app.com/admin/level_change_applications
```

#### データベース性能確認
```sql
-- 新しいテーブルのインデックス使用状況
EXPLAIN ANALYZE SELECT * FROM level_change_applications WHERE status = 'pending' AND scheduled_date <= CURRENT_DATE;

-- 既存クエリの性能確認
EXPLAIN ANALYZE SELECT * FROM users JOIN user_level_histories ON users.id = user_level_histories.user_id;
```

### 3. ログ監視設定

#### アプリケーションログ
```bash
# エラーログの監視
heroku logs --tail -a your-app-name | grep ERROR

# 申請関連ログの監視
heroku logs --tail -a your-app-name | grep "Level change"
```

#### アラート設定
- エラー発生時の通知設定
- バッチジョブ失敗時の通知設定
- パフォーマンス劣化時の通知設定

## ロールバック計画

### 緊急時のロールバック手順

#### 1. アプリケーションロールバック
```bash
# Herokuの場合
heroku rollback -a your-app-name

# Git経由の場合
git revert HEAD
git push heroku main
```

#### 2. データベースロールバック
```bash
# マイグレーションのロールバック
rails db:rollback STEP=1

# 必要に応じてバックアップからの復元
psql $DATABASE_URL < backup_YYYYMMDD_HHMMSS.sql
```

#### 3. 設定のロールバック
- cron設定の削除
- 環境変数の復元
- 監視設定の復元

### ロールバック判断基準

以下の場合はロールバックを検討：
- 管理画面にアクセスできない
- データベースエラーが頻発する
- パフォーマンスが著しく劣化する
- 既存機能に影響が出る
- セキュリティ問題が発見される

## 運用開始後の監視項目

### 1. 日次監視項目
- [ ] アプリケーションの稼働状況
- [ ] エラーログの確認
- [ ] パフォーマンス指標の確認
- [ ] 申請作成数の確認

### 2. 月次監視項目
- [ ] バッチジョブの実行結果確認
- [ ] 申請処理の成功率確認
- [ ] データベース容量の確認
- [ ] パフォーマンストレンドの分析

### 3. 定期メンテナンス
- [ ] ログファイルのローテーション
- [ ] 古い申請データのアーカイブ
- [ ] データベースの最適化
- [ ] セキュリティアップデートの適用

## 緊急連絡先

### 技術担当者
- 開発チーム: dev-team@company.com
- インフラ担当: infra@company.com
- セキュリティ担当: security@company.com

### エスカレーション手順
1. 軽微な問題: 開発チームに連絡
2. 重大な問題: インフラ担当とセキュリティ担当に同時連絡
3. 緊急事態: 全関係者に即座に連絡

## 成功基準

デプロイが成功したと判断する基準：
- [ ] 全ての機能が正常に動作する
- [ ] パフォーマンスが許容範囲内
- [ ] エラー率が1%未満
- [ ] ユーザーからの問い合わせがない
- [ ] 24時間安定稼働する

## 完了報告

デプロイ完了後、以下の情報を含む報告書を作成：
- デプロイ実行日時
- 実行した手順
- 発生した問題と対処方法
- パフォーマンス測定結果
- 今後の改善点