module HierarchyHelper
  # レベル名に応じたバッジクラスを返す
  def level_badge_class(level_name)
    case level_name
    when 'アジアビジネストラスト'
      'bg-danger'
    when '総代理店'
      'bg-warning text-dark'
    when '代理店'
      'bg-primary'
    when 'アドバイザー'
      'bg-success'
    when 'アドバイザー認定前'
      'bg-info'
    when 'サポーター'
      'bg-dark'
    when 'サロン'
      'bg-secondary'
    when 'クリニック'
      'bg-light text-dark'
    when 'お客様'
      'bg-secondary text-white'
    else
      'bg-secondary'
    end
  end

  # WOTTレベル名に応じたバッジクラスを返す
  def wott_level_badge_class(level_name)
    case level_name
    when '総代理店'
      'bg-warning text-dark'
    when '代理店'
      'bg-primary'
    when 'サポーター'
      'bg-dark'
    else
      'bg-secondary'
    end
  end
end
