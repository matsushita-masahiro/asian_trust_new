class Address < ApplicationRecord
  belongs_to :user
  
  # 住所タイプの定義（将来的な拡張を考慮）
  enum :address_type, {
    registration: 'registration',  # 登録住所（請求先住所）
    shipping: 'shipping'           # 配送先住所
  }
  
  # 住所タイプの表示名
  def self.address_type_labels
    {
      'registration' => '登録住所',
      'shipping' => '配送先住所'
    }
  end
  
  def address_type_label
    self.class.address_type_labels[address_type] || address_type
  end
  
  # バリデーション
  validates :user_id, :address_type, :address, presence: true
  validates :address_type, uniqueness: { scope: :user_id }
  validates :postal_code, format: { with: /\A\d{3}-?\d{4}\z/ }, allow_blank: true
  
  # コールバック
  before_save :format_postal_code
  
  private
  
  def format_postal_code
    if postal_code.present?
      # ハイフンなしの場合はハイフンを追加
      self.postal_code = postal_code.gsub(/\D/, '').gsub(/(\d{3})(\d{4})/, '\1-\2')
    end
  end
end