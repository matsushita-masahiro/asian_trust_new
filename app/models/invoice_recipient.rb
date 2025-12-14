class InvoiceRecipient < ApplicationRecord
  belongs_to :user, optional: true
  has_many   :invoices, dependent: :nullify

  # バリデーション
  validates :name, presence: true
  validates :address, presence: true
  validates :invoice_registration_number, format: { 
    with: /\AT\d{13}\z/, 
    message: "は「T」から始まる14桁の形式で入力してください（例：T1234567890123）" 
  }, allow_blank: true
end