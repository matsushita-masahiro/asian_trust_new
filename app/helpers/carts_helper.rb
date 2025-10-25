module CartsHelper
  # 住所選択のためのヘルパーメソッド
  
  # 住所の存在チェック
  def address_exists?(address)
    address&.postal_code.present? && address&.address.present?
  end
  
  # ユーザーの住所情報を取得
  def user_address_info(user)
    registration_addr = user.registration_address
    shipping_addr = user.shipping_address
    
    {
      registration: {
        address: registration_addr,
        exists: address_exists?(registration_addr)
      },
      shipping: {
        address: shipping_addr,
        exists: address_exists?(shipping_addr)
      }
    }
  end
  
  # デフォルト選択される住所タイプを決定
  def default_address_type(address_info)
    if address_info[:shipping][:exists]
      'shipping'  # 配送先住所を優先
    elsif address_info[:registration][:exists]
      'registration'  # 登録住所をフォールバック
    else
      nil  # 住所未登録
    end
  end
  
  # 住所の詳細表示用フォーマット
  def format_address_display(address)
    return '' unless address_exists?(address)
    "〒#{address.postal_code}<br>#{address.address}".html_safe
  end
  
  # 住所選択ラジオボタンのチェック状態を決定
  def address_radio_checked?(address_type, default_type)
    address_type == default_type
  end
  
  # 住所選択が可能かどうか
  def can_select_address?(address_info)
    address_info[:registration][:exists] || address_info[:shipping][:exists]
  end
end
