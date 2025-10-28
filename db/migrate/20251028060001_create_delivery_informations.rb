class CreateDeliveryInformations < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_informations do |t|
      t.references :purchase, null: false, foreign_key: true
      t.string :delivery_type, null: false # 'home', 'clinic', 'multiple'
      t.references :clinic, null: true, foreign_key: { to_table: :users } # クリニックのuser_id
      t.string :address_type # 'registration', 'shipping'
      t.text :delivery_address # 実際の配送先住所（スナップショット）
      t.text :delivery_notes # 配送に関する備考

      t.timestamps
    end
    
    add_index :delivery_informations, [:purchase_id, :delivery_type]
  end
end
