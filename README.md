
  
  

  
  
  購入
  curl -X POST https://asiantrust-e236e749fb27.herokuapp.com/webhooks/lstep/purchase \
  -H "Content-Type: application/json" \
  -H "X-LSTEP-SECRET: test_token_123" \
  -d '{
    "referrer_id": "lstep_0038",
    "product_id": 4,
    "unit_price": 30000,
    "quantity": 10,
    "customer_name": "Heroku 太郎",
    "customer_email": "heroku.taro@example.com",
    "customer_phone": "08099999999",
    "customer_address": "川崎市高津区溝口1-1"
  }'



  curl -X POST http://127.0.0.1:3000/webhooks/lstep \
  -H "Content-Type: application/json" \
  -H "X-LSTEP-SECRET: test_token_123" \
  -d '{
    "name": "新しいアドバイザー",
    "email": "new_advisor@example.com",
    "user_id": "lstep_0060",
    "referrer_id": "lstep_0057",
    "level_id": 4
  }'
  


  User.all.each do |u| u.update(password: "password") end

User.all.each do |user| user.password = "111111" user.password_confirmation = "111111" user.save!(validate: false) end

  class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice_recipient

  # ステータス定数
  DRAFT = 0
  SENT = 1
  CONFIRMED = 2
  
  # ステータスのバリデーション
  validates :status, inclusion: { in: [DRAFT, SENT, CONFIRMED] }
  
  # ステータス判定メソッド
  def draft?
    status == DRAFT
  end
  
  def sent?
    status == SENT
  end
  
  def confirmed?
    status == CONFIRMED
  end
  
  # ステータス変更メソッド
  def draft!
    update!(status: DRAFT)
  end
  
  def sent!
    update!(status: SENT)
  end
  
  def confirmed!
    update!(status: CONFIRMED)
  end
  
  # スコープ
  scope :draft, -> { where(status: DRAFT) }
  scope :sent, -> { where(status: SENT) }
  scope :confirmed, -> { where(status: CONFIRMED) }
  
  # ステータス名を取得
  def status_name
    case status
    when DRAFT then 'draft'
    when SENT then 'sent'
    when CONFIRMED then 'confirmed'
    else 'unknown'
    end
  end
  
  # ステータス表示名を取得
  def status_display_name
    case status
    when DRAFT then '下書き'
    when SENT then '送付済み'
    when CONFIRMED then '振込確認済み'
    else '不明'
    end
  end
  
end


------------------


class InvoiceRecipient < ApplicationRecord
  belongs_to :user, optional: true
  has_many   :invoices, dependent: :nullify

  # バリデーション
  validates :name, presence: true
  validates :address, presence: true
end

--------------

class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice_recipient, null: false, foreign_key: true

      t.date :invoice_date
      t.date :due_date
      t.integer :total_amount

      t.string :bank_name
      t.string :bank_branch_name
      t.string :bank_account_type
      t.string :bank_account_number
      t.string :bank_account_name
      t.integer :status, default: 0, null: false
      t.text :notes
      t.datetime :sent_at
      t.timestamps
    end
  end
end


^^^^^^^^^^^^^^^^^^^^



class CreateInvoiceRecipients < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_recipients do |t|
      t.references :user, null: false, foreign_key: true

      t.string :name
      t.string :email
      t.string :postal_code
      t.string :address
      t.string :tel
      t.string :department
      t.text :notes
      t.string :representative_name
      t.timestamps
    end
  end
end


admin/index.html.erbの
5行目の管理ダッシュボードの右に下記を設置する
invoiceデータのstatusが’1’になってる（送付済み）レコードがあれば
「未確認請求書有（レコード件数）」を赤背景でボタン表示。

そのボタンをクリックすると
/admin/invoice_statusに遷移する

admin/invoice_status/index.html.erb
invoiceデータのstatusが’2’になってる（送付済み）レコードがあれば
の5行目の請求書状況管理の右端に
「確認済み（レコード件数）」を表示したい







  