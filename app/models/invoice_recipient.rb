class InvoiceRecipient < ApplicationRecord
  belongs_to :user
  has_many   :invoices, dependent: :nullify

end
