class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice_recipient
end
