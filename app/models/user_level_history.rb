class UserLevelHistory < ApplicationRecord
  belongs_to :user
  belongs_to :level
  belongs_to :previous_level, class_name: 'Level', optional: true
  belongs_to :changed_by, class_name: 'User'

  validates :effective_from, presence: true
  validates :user_id, presence: true
  validates :level_id, presence: true
  validates :change_reason, presence: true
  validates :changed_by_id, presence: true

  # 指定日時で有効な履歴を取得
  scope :effective_at, ->(datetime) {
    where('effective_from <= ? AND (effective_to IS NULL OR effective_to > ?)', datetime, datetime)
  }

  # 現在有効な履歴（effective_toがnull）
  scope :current, -> { where(effective_to: nil) }

  # 過去の履歴（effective_toが設定済み）
  scope :historical, -> { where.not(effective_to: nil) }

  # 最新順
  scope :recent, -> { order(created_at: :desc) }

  # 有効期間順
  scope :by_effective_date, -> { order(:effective_from) }
end