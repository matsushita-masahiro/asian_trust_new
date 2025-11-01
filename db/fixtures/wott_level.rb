# WottLevel seed data

# 既存のWOTTレベルを全て削除してから再作成
WottLevel.destroy_all

WottLevel.seed(:id,
  { id: 1, name: "アジアビジネストラスト", value: 0 },
  { id: 2, name: "総代理店", value: 1 },
  { id: 3, name: "代理店", value: 2 },
  { id: 4, name: "サポーター", value: 3 },
  { id: 5, name: "サロン", value: 4 },
  { id: 6, name: "クリニック", value: 5 },
  { id: 7, name: "お客様", value: 6 }
)