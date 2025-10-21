# レベル変更申請システム 互換性テスト

## インセンティブ計算機能の動作確認

### テストケース1: 申請中のユーザーのインセンティブ計算

**前提条件:**
- ユーザーAが「代理店」レベル
- ユーザーAに「総代理店」への変更申請が存在（pending状態）
- ユーザーAの子孫が購入を行う

**期待結果:**
- インセンティブ計算は現在のレベル（代理店）で行われる
- 申請中のレベル（総代理店）は計算に影響しない

**確認方法:**
```ruby
# Railsコンソールでテスト
user = User.find(user_id)
purchase_date = Date.current
current_level = user.level_at(purchase_date)
puts "Current level: #{current_level.name}"

# 申請があっても現在のレベルが返されることを確認
pending_app = LevelChangeApplication.where(user: user, status: 'pending').first
puts "Pending application: #{pending_app&.target_level&.name || 'None'}"
puts "Level used for calculation: #{user.level_at(purchase_date).name}"
```

### テストケース2: レベル変更実行後のインセンティブ計算

**前提条件:**
- ユーザーBのレベルが「代理店」から「総代理店」に変更された（2024年2月1日）
- 2024年1月の購入と2024年3月の購入が存在

**期待結果:**
- 2024年1月の購入: 「代理店」レベルで計算
- 2024年3月の購入: 「総代理店」レベルで計算

**確認方法:**
```ruby
user = User.find(user_id)

# 変更前の日付でのレベル確認
jan_level = user.level_at(Date.new(2024, 1, 15))
puts "January level: #{jan_level.name}"

# 変更後の日付でのレベル確認
mar_level = user.level_at(Date.new(2024, 3, 15))
puts "March level: #{mar_level.name}"

# インセンティブ計算が正しく行われることを確認
jan_bonus = user.bonus_in_month('2024-01')
mar_bonus = user.bonus_in_month('2024-03')
puts "January bonus: #{jan_bonus}"
puts "March bonus: #{mar_bonus}"
```

### テストケース3: 履歴の整合性確認

**前提条件:**
- レベル変更申請が実行された
- user_level_historiesテーブルに正しく記録されている

**期待結果:**
- 古い履歴のeffective_toが設定されている
- 新しい履歴のeffective_fromが正しく設定されている
- 履歴の連続性が保たれている

**確認方法:**
```ruby
user = User.find(user_id)
histories = user.user_level_histories.order(:effective_from)

histories.each_with_index do |history, index|
  puts "History #{index + 1}:"
  puts "  Level: #{history.level.name}"
  puts "  From: #{history.effective_from}"
  puts "  To: #{history.effective_to || 'Current'}"
  puts "  Reason: #{history.change_reason}"
  puts
end

# 現在のレベルが最新の履歴と一致することを確認
current_history = histories.where(effective_to: nil).first
puts "Current level matches history: #{user.level == current_history.level}"
```

## レベル履歴表示機能の動作確認

### テストケース4: 管理画面での履歴表示

**確認項目:**
- ユーザー詳細画面でレベル履歴が正しく表示される
- ユーザー編集画面でレベル履歴が正しく表示される
- 申請管理画面で履歴が正しく表示される

**確認方法:**
1. 管理画面にアクセス
2. 対象ユーザーの詳細画面を表示
3. レベル履歴セクションを確認
4. 申請履歴と実行履歴が正しく表示されることを確認

## 既存機能への影響確認

### テストケース5: 紹介関係の維持

**確認項目:**
- レベル変更申請・実行後も紹介関係が維持される
- 子孫ユーザーの取得が正常に動作する
- インセンティブ計算の対象ユーザーが正しく特定される

### テストケース6: 権限・認証機能

**確認項目:**
- 管理者のみが申請を作成できる
- 管理者パスワード認証が正常に動作する
- 申請のキャンセル権限が正しく制御される

## パフォーマンステスト

### テストケース7: 大量データでの動作確認

**前提条件:**
- 100件以上の申請データ
- 1000件以上のレベル履歴データ

**確認項目:**
- バッチジョブの実行時間
- インセンティブ計算の実行時間
- 管理画面の表示速度

## エラーハンドリングテスト

### テストケース8: 異常系の動作確認

**テストシナリオ:**
1. データベース接続エラー時の動作
2. 不正なデータでの申請作成
3. 重複申請の防止
4. バッチジョブ実行中の障害

**期待結果:**
- 適切なエラーメッセージが表示される
- ログに詳細な情報が記録される
- システムが安全に停止する
- 通知機能が正常に動作する