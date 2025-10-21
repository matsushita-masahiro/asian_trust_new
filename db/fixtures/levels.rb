# ProductPriceが参照しているため、destroy_allではなくseedのupsert機能を使用

Level.seed(:value,
  { name: 'アジアビジネストラスト', value: 0 },
  { name: '総代理店',             value: 1 },
  { name: '代理店',                 value: 2 },
  { name: 'アドバイザー',           value: 3 },
  { name: 'サロン',                 value: 4 },
  { name: 'クリニック',             value: 5 },
  { name: 'サポーター',             value: 6 },
  { name: 'お客様',                 value: 7 }
)
