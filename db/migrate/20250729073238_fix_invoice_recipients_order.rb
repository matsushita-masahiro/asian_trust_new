class FixInvoiceRecipientsOrder < ActiveRecord::Migration[8.0]
  def up
    # invoicesテーブルの外部キー制約を一時的に削除
    if table_exists?(:invoices) && foreign_key_exists?(:invoices, :invoice_recipients)
      remove_foreign_key :invoices, :invoice_recipients
    end
    
    # invoice_recipientsテーブルが存在しない場合は作成
    unless table_exists?(:invoice_recipients)
      create_table :invoice_recipients do |t|
        t.references :user, null: false, foreign_key: true
        t.string :name
        t.string :email
        t.string :postal_code
        t.string :address
        t.string :tel
        t.string :department
        t.text :notes

        t.timestamps
      end
    end
    
    # invoicesテーブルが存在する場合、外部キー制約を再追加
    if table_exists?(:invoices) && column_exists?(:invoices, :invoice_recipient_id)
      add_foreign_key :invoices, :invoice_recipients
    end
  end

  def down
    # 何もしない（ロールバック時の処理）
  end
end
