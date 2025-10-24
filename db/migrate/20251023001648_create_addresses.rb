class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address_type, null: false
      t.string :postal_code
      t.text :address, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # ユニークインデックス(user_id, address_type) - 各ユーザーは各住所タイプにつき1つの住所のみ
    add_index :addresses, [:user_id, :address_type], unique: true, name: 'index_addresses_on_user_id_and_address_type'
    
    # パフォーマンス向上のための個別インデックス
    # user_idのインデックスはt.referencesで自動作成されるため省略
    add_index :addresses, :address_type, name: 'index_addresses_on_address_type'
    add_index :addresses, :deleted_at, name: 'index_addresses_on_deleted_at'
    
    # 複合インデックス - ソフトデリート対応の検索最適化
    add_index :addresses, [:user_id, :deleted_at], name: 'index_addresses_on_user_id_and_deleted_at'
  end
end
