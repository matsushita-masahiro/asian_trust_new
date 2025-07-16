class Customer < ApplicationRecord
  has_many :purchases, dependent: :destroy
end
