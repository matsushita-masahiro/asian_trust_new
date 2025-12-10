# app/models/inquiry.rb
class Inquiry < ApplicationRecord
  belongs_to :user, optional: true
  
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  has_many :answers, dependent: :destroy
end
