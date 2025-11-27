class WottLevelUpgradeRequest < ApplicationRecord
  belongs_to :user
  belongs_to :current_wott_level, class_name: 'Level', optional: true
  belongs_to :requested_wott_level, class_name: 'Level'
  belongs_to :processed_by, class_name: 'User', optional: true
  belongs_to :purchase, optional: true

  enum :status, {
    pending: 'pending',     # 承認待ち
    approved: 'approved',   # 承認済み
    rejected: 'rejected'    # 却下
  }, default: :pending

  validates :user_id, presence: true
  validates :requested_wott_level_id, presence: true
  validates :status, presence: true

  scope :pending_requests, -> { where(status: 'pending').order(created_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # 承認処理
  def approve!(admin_user, notes: nil)
    transaction do
      self.status = 'approved'
      self.processed_by = admin_user
      self.processed_at = Time.current
      self.admin_notes = notes if notes.present?
      save!

      # ユーザーのWOTTレベルを更新
      user.update!(wott_level_id: requested_wott_level_id)
    end
  end

  # 却下処理
  def reject!(admin_user, notes: nil)
    self.status = 'rejected'
    self.processed_by = admin_user
    self.processed_at = Time.current
    self.admin_notes = notes if notes.present?
    save!
  end

  # 表示用の情報
  def current_level_name
    current_wott_level&.name || 'なし'
  end

  def requested_level_name
    requested_wott_level&.name
  end
end
