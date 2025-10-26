class AddAdvisorToWottLevels < ActiveRecord::Migration[8.0]
  def up
    # アドバイザーレベルを追加（代理店とサポーターの間に挿入）
    WottLevel.create!(name: 'アドバイザー', value: 35)
    
    # 既存のレベルの順序を調整
    # アジアビジネストラスト: 10
    # 総代理店: 20  
    # 代理店: 30
    # アドバイザー: 35 (新規追加)
    # サポーター: 40
    # サロン: 50
    # クリニック: 60
    # お客様: 70
    
    WottLevel.find_by(name: 'サポーター')&.update!(value: 40)
    WottLevel.find_by(name: 'サロン')&.update!(value: 50)
    WottLevel.find_by(name: 'クリニック')&.update!(value: 60)
    WottLevel.find_by(name: 'お客様')&.update!(value: 70)
  end
  
  def down
    # アドバイザーレベルを削除
    WottLevel.find_by(name: 'アドバイザー')&.destroy
    
    # 元の順序に戻す
    WottLevel.find_by(name: 'サポーター')&.update!(value: 30)
    WottLevel.find_by(name: 'サロン')&.update!(value: 40)
    WottLevel.find_by(name: 'クリニック')&.update!(value: 50)
    WottLevel.find_by(name: 'お客様')&.update!(value: 60)
  end
end
