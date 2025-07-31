
  
  

  
  
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

現在
invoiceの
statusが
invoice.rbで下記になってますが

# ステータス定数
DRAFT = 0 下書き
SENT = 1 送付済み
CONFIRMED = 2 振込確認済み

INITIAL = 0 初期状態
DRAFT = 1 下書き
SENT = 2 送付済み
CONFIRMED = 3 振込確認済み

に変更したいが

そうするといろんな部分でコードを修正しないとエラーにや変な動きになる
ちゃんとチェックしながら実装できますか？


-----------------------------------------


<div class="header">
  <div style="display: flex; justify-content: space-between; align-items: flex-start;">
    <div>
      <h1 class="invoice-title">請求書</h1>
      <div class="invoice-info">
        <p>請求書番号: INV-<%= @invoice.id.to_s.rjust(6, '0') %></p>
        <p>発行日: <%= @invoice.invoice_date&.strftime("%Y年%m月%d日") %></p>
        <p>支払期限: <%= @invoice.due_date&.strftime("%Y年%m月%d日") %></p>
      </div>
    </div>
    <div class="company-info">
      <% if @user.invoice_base %>
        <h3><%= @user.invoice_base.company_name %></h3>
        <% if @user.invoice_base.department.present? %>
          <p><%= @user.invoice_base.department %></p>
        <% end %>
        <% if @user.invoice_base.address.present? %>
          <p><%= @user.invoice_base.address %></p>
        <% end %>
        <% if @user.invoice_base.email.present? %>
          <p><%= @user.invoice_base.email %></p>
        <% end %>
      <% else %>
        <h3><%= @user.name || @user.email %></h3>
      <% end %>
    </div>
  </div>
</div>

<!-- 請求先情報 -->
<div class="recipient-info">
  <div class="section-title">請求先</div>
  <% if @invoice.invoice_recipient %>
    <p><strong><%= @invoice.invoice_recipient.name %></strong></p>
    <% if @invoice.invoice_recipient.representative_name.present? %>
      <p><%= @invoice.invoice_recipient.representative_name %> 様</p>
    <% end %>
    <% if @invoice.invoice_recipient.department.present? %>
      <p><%= @invoice.invoice_recipient.department %></p>
    <% end %>
    <% if @invoice.invoice_recipient.address.present? %>
      <p><%= @invoice.invoice_recipient.address %></p>
    <% end %>
  <% end %>
</div>

<!-- 請求金額 -->
<div class="amount-section">
  <div class="amount-label">請求金額</div>
  <div class="amount-value">¥<%= number_with_delimiter(@invoice.total_amount) %></div>
</div>

<!-- 明細表 -->
<% if @bonus_details && @bonus_details.any? %>
  <div class="details-section">
    <div class="section-title">インセンティブ明細</div>
    <table class="details-table">
      <thead>
        <tr>
          <th>種別</th>
          <th>販売者</th>
          <th>商品名</th>
          <th>数量</th>
          <th>単価</th>
          <th>金額</th>
          <th>日付</th>
        </tr>
      </thead>
      <tbody>
        <% total_amount = 0 %>
        <% @bonus_details.each do |detail| %>
          <% total_amount += detail[:total_bonus] %>
          <tr>
            <td><%= detail[:type] %></td>
            <td><%= detail[:user_name] %></td>
            <td><%= detail[:product_name] %></td>
            <td><%= detail[:quantity] %></td>
            <td>¥<%= number_with_delimiter(detail[:unit_bonus]) %></td>
            <td>¥<%= number_with_delimiter(detail[:total_bonus]) %></td>
            <td><%= detail[:purchased_at]&.strftime("%m/%d") %></td>
          </tr>
        <% end %>
        <tr class="total-row">
          <td colspan="5"><strong>合計</strong></td>
          <td><strong>¥<%= number_with_delimiter(total_amount) %></strong></td>
          <td></td>
        </tr>
      </tbody>
    </table>
  </div>
<% end %>

<!-- 備考 -->
<% if @invoice.notes.present? %>
  <div class="notes">
    <div class="section-title">備考</div>
    <p><%= simple_format(@invoice.notes) %></p>
  </div>
<% end %>

<!-- 振込先情報 -->
<div class="bank-info">
  <div class="section-title">お振込先</div>
  <table>
    <tr>
      <td>銀行名:</td>
      <td><%= @invoice.bank_name %></td>
    </tr>
    <tr>
      <td>支店名:</td>
      <td><%= @invoice.bank_branch_name %></td>
    </tr>
    <tr>
      <td>口座種別:</td>
      <td>
        <% if @invoice.bank_account_type == 'savings' %>
          普通
        <% elsif @invoice.bank_account_type == 'checking' %>
          当座
        <% else %>
          <%= @invoice.bank_account_type %>
        <% end %>
      </td>
    </tr>
    <tr>
      <td>口座番号:</td>
      <td><%= @invoice.bank_account_number %></td>
    </tr>
    <tr>
      <td>口座名義:</td>
      <td><%= @invoice.bank_account_name %></td>
    </tr>
  </table>
</div>











  