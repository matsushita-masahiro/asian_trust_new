class ReferralInvitation < ApplicationRecord
  belongs_to :referrer, class_name: 'User'
  belongs_to :target_level, class_name: 'Level'
  belongs_to :invited_user, class_name: 'User', optional: true

  validates :referral_token, presence: true, uniqueness: true
  validates :passcode, presence: true, length: { is: 4 }
  validate :target_level_must_be_lower_than_referrer
  
  scope :active, -> { where(used_at: nil).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :used, -> { where.not(used_at: nil) }

  before_validation :generate_token_and_passcode, on: :create
  before_validation :set_expiration, on: :create

  def active?
    used_at.nil? && expires_at > Time.current
  end

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def mark_as_used!(user)
    update!(used_at: Time.current, invited_user: user)
  end

  def referral_url
    "#{Rails.application.config.force_ssl ? 'https' : 'http'}://localhost:3000/users/sign_up?ref=#{referral_token}"
  end

  private

  def generate_token_and_passcode
    self.referral_token = generate_unique_token if referral_token.blank?
    self.passcode = generate_passcode if passcode.blank?
  end

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(12)
      break token unless ReferralInvitation.exists?(referral_token: token)
    end
  end

  def generate_passcode
    4.times.map { rand(10) }.join
  end

  def set_expiration
    self.expires_at = 7.days.from_now if expires_at.blank?
  end

  def target_level_must_be_lower_than_referrer
    return unless referrer&.level&.value && target_level&.value
    
    if target_level.value <= referrer.level.value
      errors.add(:target_level, 'は紹介者より低いレベルを選択してください')
    end
  end
end
