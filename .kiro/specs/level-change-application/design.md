# 会員レベル変更申請システム 設計書

## Overview

会員レベル変更を即座に実行する現在のシステムから、申請ベースのワークフローシステムに変更します。申請は翌月1日に自動実行され、履歴管理と通知機能を含む包括的なシステムを構築します。

## Architecture

### システム構成
```
[管理者] → [申請画面] → [申請DB] → [バッチジョブ] → [レベル変更実行] → [通知]
                           ↓
                      [申請管理画面]
```

### データフロー
1. 管理者が申請を作成
2. 申請情報をDBに保存
3. 毎月1日にバッチジョブが実行
4. pending申請を取得してレベル変更実行
5. 実行結果を記録し通知送信

## Components and Interfaces

### 1. LevelChangeApplication モデル

新しいモデルを作成して申請情報を管理：

```ruby
class LevelChangeApplication < ApplicationRecord
  belongs_to :user                    # 対象ユーザー
  belongs_to :current_level, class_name: 'Level'  # 変更前レベル
  belongs_to :target_level, class_name: 'Level'   # 変更後レベル
  belongs_to :applicant, class_name: 'User'       # 申請者
  
  enum status: {
    pending: 'pending',       # 申請中
    completed: 'completed',   # 実行完了
    cancelled: 'cancelled',   # キャンセル
    error: 'error'           # 実行エラー
  }
  
  validates :reason, presence: true
  validates :scheduled_date, presence: true
  
  scope :executable, -> { where(status: 'pending', scheduled_date: Date.current) }
end
```

### 2. Admin::LevelChangeApplicationsController

申請管理用のコントローラー：

```ruby
class Admin::LevelChangeApplicationsController < Admin::BaseController
  def index     # 申請一覧
  def show      # 申請詳細
  def cancel    # 申請キャンセル
end
```

### 3. LevelChangeExecutorJob

レベル変更実行用のジョブ：

```ruby
class LevelChangeExecutorJob < ApplicationJob
  def perform
    # pending申請を取得
    # 各申請に対してレベル変更実行
    # 実行結果を記録
    # 通知送信
  end
end
```

### 4. 既存コントローラーの修正

Admin::UsersControllerのupdateアクションを修正：
- レベル変更時は申請を作成
- 即座のレベル変更は行わない

## Data Models

### level_change_applications テーブル

```sql
CREATE TABLE level_change_applications (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  current_level_id BIGINT NOT NULL,
  target_level_id BIGINT NOT NULL,
  applicant_id BIGINT NOT NULL,
  reason TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  scheduled_date DATE NOT NULL,
  executed_at TIMESTAMP NULL,
  error_message TEXT NULL,
  ip_address VARCHAR(45),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (current_level_id) REFERENCES levels(id),
  FOREIGN KEY (target_level_id) REFERENCES levels(id),
  FOREIGN KEY (applicant_id) REFERENCES users(id),
  
  INDEX idx_status_scheduled (status, scheduled_date),
  INDEX idx_user_status (user_id, status)
);
```

### 既存テーブルへの影響

- `user_level_histories`: 既存の履歴テーブルはそのまま維持
- `users`: レベル変更は申請実行時に更新

## Error Handling

### 申請作成時のエラー
- バリデーションエラー: フォームにエラーメッセージ表示
- 認証エラー: 管理者パスワード不正の場合はエラーメッセージ
- 重複申請: 同一ユーザーの未実行申請がある場合はエラー

### バッチ実行時のエラー
- レベル変更失敗: エラーログ記録、ステータスをerrorに設定
- 通知送信失敗: ログ記録、処理は継続
- システムエラー: 管理者に緊急通知

### エラー通知
```ruby
class LevelChangeErrorNotifier
  def self.notify_execution_error(application, error)
    # 管理者にエラー通知メール送信
  end
end
```

## Testing Strategy

### 単体テスト
- LevelChangeApplicationモデルのバリデーション
- LevelChangeExecutorJobの実行ロジック
- コントローラーのアクション

### 統合テスト
- 申請作成から実行までのフロー
- エラーハンドリング
- 通知機能

### システムテスト
- 管理者による申請作成
- バッチジョブの実行
- 申請管理画面の操作

## Security Considerations

### 認証・認可
- 管理者のみが申請作成可能
- 申請作成時の管理者パスワード認証
- 申請キャンセルの権限制御

### データ保護
- 申請理由の適切な記録
- IPアドレスの記録
- 機密情報の暗号化（必要に応じて）

## Performance Considerations

### バッチ処理の最適化
- 大量申請時のメモリ使用量制御
- 実行時間の監視
- 失敗時のリトライ機能

### データベース最適化
- 適切なインデックス設定
- 古い申請データのアーカイブ
- クエリパフォーマンスの監視

## Migration Strategy

### 段階的移行
1. 新テーブル作成とモデル追加
2. 申請機能の実装
3. バッチジョブの実装
4. 既存機能の修正
5. 通知機能の追加

### 既存データの処理
- 既存のuser_level_historiesは維持
- 新システム稼働後の申請のみ新テーブルで管理

## Monitoring and Logging

### ログ記録
- 申請作成ログ
- バッチ実行ログ
- エラーログ
- パフォーマンスログ

### 監視項目
- バッチジョブの実行状況
- 申請処理の成功率
- システムエラーの発生頻度