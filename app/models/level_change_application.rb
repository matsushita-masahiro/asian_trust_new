class LevelChangeApplication < ApplicationRecord
  belongs_to :user
  belongs_to :current_level, class_name: 'Level'
  belongs_to :target_level, class_name: 'Level'
  belongs_to :applicant, class_name: 'User'

  enum :status, {
    pending: 'pending',       # 申請中
    completed: 'completed',   # 実行完了
    cancelled: 'cancelled',   # キャンセル
    error: 'error'           # 実行エラー
  }

  validates :reason, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :scheduled_date, presence: true
  validates :status, presence: true
  validates :ip_address, length: { maximum: 45 }

  # 同一ユーザーの未実行申請の重複チェック
  validate :no_duplicate_pending_application, on: :create

  # 実行対象の申請を取得
  scope :executable, -> { where(status: 'pending', scheduled_date: Date.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # 申請者の表示名
  def applicant_name
    applicant.name.present? ? applicant.name : applicant.email
  end

  # 対象ユーザーの表示名
  def user_name
    user.name.present? ? user.name : user.email
  end

  # レベル変更の内容を文字列で表示
  def level_change_description
    "#{current_level.name} → #{target_level.name}"
  end

  # 実行可能かどうか
  def executable?
    pending? && scheduled_date <= Date.current
  end

  # キャンセル可能かどうか
  def cancellable?
    pending?
  end

  # 申請を実行済みにマーク
  def mark_as_completed!
    update!(
      status: 'completed',
      executed_at: Time.current
    )
  end

  # 申請をエラー状態にマーク
  def mark_as_error!(error_msg)
    update!(
      status: 'error',
      error_message: error_msg,
      executed_at: Time.current
    )
  end

  # 申請をキャンセル
  def cancel!
    update!(status: 'cancelled')
  end

  private

  def no_duplicate_pending_application
    return unless user_id.present?

    existing = LevelChangeApplication.where(
      user_id: user_id,
      status: 'pending'
    ).where.not(id: id)

    if existing.exists?
      errors.add(:user, 'には既に未実行の申請が存在します')
    end
  end
end