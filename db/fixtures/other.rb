# 既存の購入データをクリーンアップ
puts "🧹 Cleaning up existing purchase data..."
adapter = ActiveRecord::Base.connection.adapter_name

# purchase系とその子のテーブル名（存在するものだけ使う）
candidate_tables = %w[
  delivery_informations
  purchase_items
  purchase_invoices
  receipts
  payments
  purchases
]
tables = candidate_tables.select { |t| ActiveRecord::Base.connection.table_exists?(t) }

if adapter == "SQLite"
  # 子→親の順で削除（FK一時OFF）
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
  (tables - ["purchases"]).each do |t|
    ActiveRecord::Base.connection.execute("DELETE FROM #{t}")
  end
  ActiveRecord::Base.connection.execute("DELETE FROM purchases") if tables.include?("purchases")
  # 主要テーブルのオートインクリメントをリセット（存在すれば）
  %w[purchases purchase_items delivery_informations purchase_invoices receipts payments].each do |t|
    next unless ActiveRecord::Base.connection.table_exists?(t)
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='#{t}'")
  end
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")

elsif adapter == "PostgreSQL"
  # 参照関係はDBに任せて一括クリア＋ID振り直し
  unless tables.empty?
    ActiveRecord::Base.connection.execute(
      "TRUNCATE TABLE #{tables.join(', ')} RESTART IDENTITY CASCADE"
    )
  end

else
  # フォールバック：子→親の順で削除
  (tables - ["purchases"]).each do |t|
    ActiveRecord::Base.connection.execute("DELETE FROM #{t}")
  end
  ActiveRecord::Base.connection.execute("DELETE FROM purchases") if tables.include?("purchases")
end

puts "✅ Purchase data cleanup completed"
