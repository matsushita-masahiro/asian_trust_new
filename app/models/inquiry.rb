# app/models/inquiry.rb
class Inquiry < ApplicationRecord
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  has_many :answers, dependent: :destroy

  enum status: {
    draft: 0,     # 作成しただけ
    sent: 1,      # 請求書を送付済み
    confirmed: 2  # 振込確認済み
  }
  
end
