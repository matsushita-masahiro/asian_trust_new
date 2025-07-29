# app/models/inquiry.rb
class Inquiry < ApplicationRecord
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  has_many :answers, dependent: :destroy

  
end
