class InvoiceRecipient < ApplicationRecord
  belongs_to :user, optional: true
  has_many   :invoices, dependent: :nullify

  # バリデーション
  validates :name, presence: true
  validates :address, presence: true
end