class ClinicReservation < ApplicationRecord
  belongs_to :user
  belongs_to :purchase
  
  # ステータス定数
  PENDING = 0      # 予約申込中
  CONFIRMED = 1    # 予約確定
  COMPLETED = 2    # 施術完了
  CANCELLED = 3    # キャンセル
  
  validates :treatment_methods, presence: true
  validates :preferred_date_1, presence: true
  validates :preferred_time_1, presence: true
  validates :disease_name, presence: true, if: :has_stem_cell_treatment?
  validates :current_condition, presence: true, if: :has_stem_cell_treatment?
  
  # 施術方法をJSON形式で保存・取得
  def treatment_methods_array
    return [] if treatment_methods.blank?
    JSON.parse(treatment_methods)
  rescue JSON::ParserError
    []
  end
  
  def treatment_methods_array=(methods)
    self.treatment_methods = methods.to_json
  end
  
  # 骨髄幹細胞治療が含まれているかチェック（下の4つの選択肢のみ）
  def has_stem_cell_treatment?
    target_treatments = [
      '骨髄幹細胞培養上清液お申込みの方：点滴',
      '骨髄幹細胞培養上清液お申込みの方：静脈注射', 
      '骨髄幹細胞培養上清液お申込みの方：皮下注射',
      '骨髄幹細胞培養上清液お申込みの方：骨髄幹細胞治療（1億個）'
    ]
    
    result = treatment_methods_array.any? { |method| target_treatments.include?(method) }
    Rails.logger.debug "=== has_stem_cell_treatment? DEBUG ==="
    Rails.logger.debug "Treatment methods: #{treatment_methods}"
    Rails.logger.debug "Treatment methods array: #{treatment_methods_array}"
    Rails.logger.debug "Target treatments: #{target_treatments}"
    Rails.logger.debug "Has stem cell treatment: #{result}"
    Rails.logger.debug "======================================="
    result
  end
  
  # ステータス判定メソッド
  def pending?
    status == PENDING
  end
  
  def confirmed?
    status == CONFIRMED
  end
  
  def completed?
    status == COMPLETED
  end
  
  def cancelled?
    status == CANCELLED
  end
  
  # ステータス表示名
  def status_name
    case status
    when PENDING then '予約申込中'
    when CONFIRMED then '予約確定'
    when COMPLETED then '施術完了'
    when CANCELLED then 'キャンセル'
    else '不明'
    end
  end
end
