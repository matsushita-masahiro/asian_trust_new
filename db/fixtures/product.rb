# ProductPriceが参照しているため、destroy_allではなくseedのupsert機能を使用

Product.seed(:id,
  { id: 1, name: '骨髄幹細胞培培養上清液', base_price: 50000, is_active: true, unit_quantity: 2 , unit_label: "cc" },
  { id: 2, name: '臍帯幹細胞培培養上清液', base_price: 30000, is_active: true, unit_quantity: 2 , unit_label: "cc" },
  { id: 3, name: '歯髄幹細胞培培養上清液', base_price: 30000, is_active: true, unit_quantity: 2 , unit_label: "cc" },
  { id: 4, name: '脂肪幹細胞培培養上清液', base_price: 30000, is_active: true, unit_quantity: 2 , unit_label: "cc" },
  { id: 5, name: '骨髄幹細胞', base_price: 3800000, is_active: true, unit_quantity: 1 , unit_label: "回" }
)

