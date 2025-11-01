# 既存のレベルデータを更新（外部キー制約を考慮）
# まず「お客様」のvalueを一時的に変更してUNIQUE制約を回避
customer_level = Level.find_by(name: 'お客様')
if customer_level && customer_level.value == 6
  customer_level.update!(value: 99)  # 一時的な値
end

# 新しいレベル「サポーター」を追加
Level.find_or_create_by(name: 'サポーター') do |level|
  level.value = 4
end

# 「お客様」のvalueを7に更新
if customer_level
  customer_level.update!(value: 7)
end

# 他のレベルも確認・更新
Level.find_or_create_by(name: 'アジアビジネストラスト') { |l| l.value = 0 }
Level.find_or_create_by(name: '総代理店') { |l| l.value = 1 }
Level.find_or_create_by(name: '代理店') { |l| l.value = 2 }
Level.find_or_create_by(name: 'アドバイザー') { |l| l.value = 3 }
Level.find_or_create_by(name: 'サロン') { |l| l.value = 5 }
Level.find_or_create_by(name: 'クリニック') { |l| l.value = 6 }
