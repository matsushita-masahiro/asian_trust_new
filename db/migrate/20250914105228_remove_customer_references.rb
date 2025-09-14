class RemoveCustomerReferences < ActiveRecord::Migration[8.0]
  def up
    # 1. purchasesテーブルからcustomer_idカラムと外部キー制約を削除
    remove_foreign_key :purchases, :customers if foreign_key_exists?(:purchases, :customers)
    remove_column :purchases, :customer_id if column_exists?(:purchases, :customer_id)
    
    # 2. customersテーブルを削除
    drop_table :customers if table_exists?(:customers)
  end
  
  def down
    # ロールバック処理（必要に応じて実装）
    raise ActiveRecord::IrreversibleMigration, "This migration cannot be reversed safely"
  end
end
