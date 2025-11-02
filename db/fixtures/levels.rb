# Levelデータを全削除してから再作成

# 1. 全削除（外部キー制約があるため、依存データも削除）
puts "Levelデータを削除中..."

# 外部キー制約のあるテーブルから先に削除
ProductPrice.delete_all
ReferralInvitation.delete_all

# Userのlevel_idをnullに設定
User.update_all(level_id: nil)

# Levelを削除
Level.delete_all

# SQLiteの場合はシーケンステーブルをリセット
if ActiveRecord::Base.connection.adapter_name == 'SQLite'
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='levels'")
end

puts "Levelデータを再作成中..."

# 2. 新しいレベル構成で作成
Level.create!([
  { id: 1, name: 'アジアビジネストラスト', value: 0 },
  { id: 2, name: '総代理店', value: 1 },
  { id: 3, name: '代理店', value: 2 },
  { id: 4, name: 'アドバイザー', value: 3 },
  { id: 5, name: 'アドバイザー認定前', value: 4 },
  { id: 6, name: 'サポーター', value: 5 },
  { id: 7, name: 'クリニック', value: 6 },
  { id: 8, name: 'サロン', value: 7 },
  { id: 9, name: 'お客様', value: 8 }
])

puts "✅ Levelデータの再作成完了"
puts "新しいレベル構成:"
Level.order(:value).each do |level|
  puts "  #{level.value}: #{level.name}"
end

puts "\n⚠️  注意: ProductPriceとReferralInvitationのデータも削除されました"
puts "   必要に応じて他のfixturesも再実行してください"