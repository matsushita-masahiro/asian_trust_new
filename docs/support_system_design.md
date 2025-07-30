# サポートシステム設計書

## 概要
顧客からの相談・クレーム履歴と代理店からの相談・クレーム履歴を統合管理するシステムの設計

## 1. データベース設計

### SupportCaseモデル（統一管理）
```ruby
# app/models/support_case.rb
class SupportCase < ApplicationRecord
  belongs_to :customer, optional: true  # 顧客からの場合
  belongs_to :user, optional: true      # 代理店からの場合
  belongs_to :assigned_to, class_name: 'User', optional: true  # 担当者
  
  enum case_type: { 
    customer_inquiry: 0,    # 顧客からの相談
    customer_complaint: 1,  # 顧客からのクレーム
    agent_inquiry: 2,       # 代理店からの相談
    agent_complaint: 3      # 代理店からのクレーム
  }
  
  enum status: { 
    open: 0,        # 未対応
    in_progress: 1, # 対応中
    resolved: 2,    # 解決済み
    closed: 3       # 完了
  }
  
  enum priority: { 
    low: 0,     # 低
    medium: 1,  # 中
    high: 2,    # 高
    urgent: 3   # 緊急
  }
end
```

### テーブル構造
```ruby
# db/migrate/xxx_create_support_cases.rb
create_table :support_cases do |t|
  t.references :customer, null: true, foreign_key: true
  t.references :user, null: true, foreign_key: true
  t.references :assigned_to, null: true, foreign_key: { to_table: :users }
  t.string :title, null: false
  t.text :description
  t.integer :case_type, default: 0
  t.integer :status, default: 0
  t.integer :priority, default: 1
  t.datetime :resolved_at
  t.text :resolution_notes  # 解決メモ
  t.timestamps
end
```

## 2. 実装場所の提案

### A. 管理者画面（admin）
```
/admin/support_cases
├── index     # 全サポート案件一覧
├── show      # 案件詳細
├── edit      # ステータス・担当者変更
├── new       # 手動で案件作成
└── assign    # 担当者割り当て
```

### B. 顧客詳細ページに統合
```
/customers/:id
├── 基本情報（現在実装済み）
├── 購入履歴（現在実装済み）
└── サポート履歴（新規追加）
    ├── 相談履歴
    ├── クレーム履歴
    └── 解決状況
```

### C. 代理店詳細ページに統合
```
/admin/users/:id  または  /users/:id
├── 基本情報（現在実装済み）
├── 売上情報（現在実装済み）
└── サポート履歴（新規追加）
    ├── 相談履歴
    ├── クレーム履歴
    └── 解決状況
```

## 3. 画面設計

### 3.1 customers/show.html.erb に追加
```erb
<!-- サポート履歴 -->
<div class="card shadow mt-4">
  <div class="card-header bg-warning text-white">
    <h5 class="mb-0">📞 サポート履歴</h5>
  </div>
  <div class="card-body">
    <% if @customer.support_cases.any? %>
      <div class="table-responsive">
        <table class="table table-hover">
          <thead class="table-light">
            <tr>
              <th>日付</th>
              <th>種類</th>
              <th>タイトル</th>
              <th>ステータス</th>
              <th>優先度</th>
              <th>担当者</th>
            </tr>
          </thead>
          <tbody>
            <% @customer.support_cases.order(created_at: :desc).each do |case| %>
              <tr>
                <td><%= case.created_at.strftime("%Y/%m/%d") %></td>
                <td>
                  <span class="badge bg-<%= case.customer_complaint? ? 'danger' : 'info' %>">
                    <%= case.case_type.humanize %>
                  </span>
                </td>
                <td><%= link_to case.title, admin_support_case_path(case) %></td>
                <td>
                  <span class="badge bg-<%= case.resolved? ? 'success' : 'warning' %>">
                    <%= case.status.humanize %>
                  </span>
                </td>
                <td><%= case.priority.humanize %></td>
                <td><%= case.assigned_to&.name || "未割当" %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% else %>
      <p class="text-muted">サポート履歴がありません</p>
    <% end %>
  </div>
</div>
```

### 3.2 admin/users/show.html.erb に追加
```erb
<!-- サポート履歴 -->
<div class="row mb-4">
  <div class="col-12">
    <div class="card">
      <div class="card-header">
        <h5 class="card-title mb-0">サポート履歴</h5>
      </div>
      <div class="card-body">
        <!-- 代理店からの相談・クレーム履歴 -->
        <% if @user.support_cases.any? %>
          <div class="table-responsive">
            <table class="table table-hover">
              <thead class="table-light">
                <tr>
                  <th>日付</th>
                  <th>種類</th>
                  <th>タイトル</th>
                  <th>ステータス</th>
                  <th>優先度</th>
                  <th>担当者</th>
                </tr>
              </thead>
              <tbody>
                <% @user.support_cases.order(created_at: :desc).each do |case| %>
                  <tr>
                    <td><%= case.created_at.strftime("%Y/%m/%d") %></td>
                    <td>
                      <span class="badge bg-<%= case.agent_complaint? ? 'danger' : 'primary' %>">
                        <%= case.case_type.humanize %>
                      </span>
                    </td>
                    <td><%= link_to case.title, admin_support_case_path(case) %></td>
                    <td>
                      <span class="badge bg-<%= case.resolved? ? 'success' : 'warning' %>">
                        <%= case.status.humanize %>
                      </span>
                    </td>
                    <td><%= case.priority.humanize %></td>
                    <td><%= case.assigned_to&.name || "未割当" %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <p class="text-muted">サポート履歴がありません</p>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

## 4. 管理画面での統合管理

### admin/support_cases/index.html.erb
- 全てのサポート案件を一元管理
- フィルター機能（顧客/代理店、種類、ステータス、優先度）
- 検索機能（顧客名、代理店名、タイトル）
- 担当者割り当て機能
- 一括ステータス更新機能

### 機能要件
1. **案件作成**: 電話対応時に手動で案件を作成
2. **ステータス管理**: 対応状況を追跡
3. **担当者割り当て**: 適切な担当者に案件を割り当て
4. **優先度設定**: 緊急度に応じた優先度管理
5. **解決記録**: 解決内容と対応方法を記録
6. **レポート機能**: 月次・年次のサポート状況レポート

## 5. メリット

### 統一管理のメリット
- **一元管理**: 全てのサポート案件を一箇所で管理
- **効率的**: 担当者割り当てやステータス管理が統一
- **分析可能**: 顧客満足度や問題傾向の分析が容易
- **追跡可能**: 案件の進捗状況を明確に追跡
- **品質向上**: 対応品質の標準化と向上

### 分散表示のメリット
- **文脈理解**: 顧客/代理店の詳細と合わせて履歴を確認
- **関連性**: 購入履歴や売上と関連付けて問題を理解
- **アクセス性**: 各詳細ページから直接履歴を確認
- **効率性**: 関連情報を一画面で確認可能

## 6. 実装順序

### フェーズ1: 基盤構築
1. **SupportCaseモデル作成**
2. **マイグレーション実行**
3. **基本的なCRUD機能実装**

### フェーズ2: 管理機能
1. **admin/support_cases（管理画面）実装**
2. **フィルター・検索機能追加**
3. **担当者割り当て機能実装**

### フェーズ3: 統合表示
1. **customers/showにサポート履歴追加**
2. **admin/users/showにサポート履歴追加**
3. **関連情報の表示改善**

### フェーズ4: 高度な機能
1. **レポート機能実装**
2. **通知機能（メール・Slack等）**
3. **API連携（電話システムとの連携など）**

## 7. 技術仕様

### 使用技術
- **フレームワーク**: Ruby on Rails
- **データベース**: PostgreSQL/MySQL
- **フロントエンド**: Bootstrap 5
- **認証**: Devise

### セキュリティ考慮事項
- **アクセス制御**: 管理者のみがサポート案件を管理可能
- **データ保護**: 個人情報の適切な取り扱い
- **監査ログ**: 案件の変更履歴を記録

## 8. 運用考慮事項

### データ管理
- **定期バックアップ**: サポートデータの定期的なバックアップ
- **データ保持期間**: 法的要件に応じたデータ保持期間の設定
- **アーカイブ**: 古い案件のアーカイブ機能

### パフォーマンス
- **インデックス**: 検索性能向上のための適切なインデックス設定
- **ページネーション**: 大量データの効率的な表示
- **キャッシュ**: 頻繁にアクセスされるデータのキャッシュ

この設計により、顧客と代理店の両方のサポート履歴を効率的に管理し、
サービス品質の向上と顧客満足度の向上を実現できます。