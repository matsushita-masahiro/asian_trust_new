# ProductPriceが参照しているため、destroy_allではなくseedのupsert機能を使用

Level.seed(:id,
  { id: 1, name: 'アジアビジネストラスト', value: 0 },
  { id: 2, name: '特約代理店',             value: 1 },
  { id: 3, name: '代理店',                 value: 2 },
  { id: 4, name: 'アドバイザー',           value: 3 },
  { id: 5, name: 'サロン',                 value: 4 },
  { id: 6, name: 'クリニック',             value: 5 },
  { id: 7, name: 'お客様',                 value: 6 }
)
