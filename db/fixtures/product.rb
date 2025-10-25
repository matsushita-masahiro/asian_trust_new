# ProductPriceが参照しているため、destroy_allではなくseedのupsert機能を使用

Product.seed(:id,
  # 上清液4種 (category: sl) - 税別価格
  { id: 1, name: '骨髄幹細胞培培養上清液', short_name: '骨髄', base_price: 40000, is_active: true, unit_quantity: 2 , unit_label: "cc", category: "sl", tax_included: false, description: "骨髄由来の幹細胞培養上清液です。再生医療に使用される高品質な製品です。" },
  { id: 2, name: '臍帯幹細胞培培養上清液', short_name: '臍帯', base_price: 30000, is_active: true, unit_quantity: 2 , unit_label: "cc", category: "sl", tax_included: false, description: "臍帯由来の幹細胞培養上清液です。安全性と効果が確認された製品です。" },
  { id: 3, name: '歯髄幹細胞培培養上清液', short_name: '歯髄', base_price: 30000, is_active: true, unit_quantity: 2 , unit_label: "cc", category: "sl", tax_included: false, description: "歯髄由来の幹細胞培養上清液です。歯科治療に最適な製品です。" },
  { id: 4, name: '脂肪幹細胞培培養上清液', short_name: '脂肪', base_price: 30000, is_active: true, unit_quantity: 2 , unit_label: "cc", category: "sl", tax_included: false, description: "脂肪由来の幹細胞培養上清液です。美容医療に広く使用されています。" },
  { id: 5, name: '骨髄幹細胞', short_name: '骨髄幹細胞', base_price: 3800000, is_active: true, unit_quantity: 1 , unit_label: "回", category: "sl", tax_included: false, description: "骨髄幹細胞治療の施術です。高度な再生医療技術を提供します。" },
  
  # WOTT商品 (category: wott) - 税別価格
  { id: 6, name: 'WOTT Device', short_name: 'WOTT', base_price: 1100000, is_active: true, unit_quantity: 1 , unit_label: "台", category: "wott", tax_included: false, description: "革新的なWOTT技術を搭載したデバイスです。健康管理に最適な製品です。" },
  
  # MANNERSOUND商品 (category: ms) - 8種類 - 税込価格
  { id: 7, name: 'お金を呼ぶ特殊音響シリーズ', short_name: 'MS I', base_price: 143000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "金運向上に特化した特殊音響技術を使用したシリーズです。6種類の音響デザインが含まれています。" },
  { id: 8, name: '仕事運向上シリーズ', short_name: 'MS II', base_price: 143000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "仕事運とキャリアアップをサポートする音響シリーズです。6種類の専用音響が含まれています。" },
  { id: 9, name: '睡眠向上癒しシリーズ', short_name: 'MS III', base_price: 121000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "質の高い睡眠と心身の癒しを促進する音響シリーズです。5種類の癒し音響が含まれています。" },
  { id: 10, name: '人間関係良好シリーズ', short_name: 'MS IV', base_price: 121000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "人間関係の改善とコミュニケーション能力向上をサポートします。5種類の音響デザインが含まれています。" },
  { id: 11, name: '身体の免疫向上シリーズ', short_name: 'MS V', base_price: 121000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "免疫力向上と身体機能の最適化をサポートする音響シリーズです。6種類の健康音響が含まれています。" },
  { id: 12, name: '運気上昇シリーズ', short_name: 'MS VI', base_price: 121000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "総合的な運気向上をサポートする音響シリーズです。5種類の運気向上音響が含まれています。" },
  { id: 13, name: '恋愛結婚運上昇シリーズ', short_name: 'MS VII', base_price: 121000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "恋愛運と結婚運の向上をサポートする特別な音響シリーズです。5種類のロマンス音響が含まれています。" },
  { id: 14, name: '髪の健康ケアシリーズ', short_name: 'MS VIII', base_price: 121000, is_active: true, unit_quantity: 1 , unit_label: "セット", category: "ms", tax_included: true, description: "髪の健康と育毛をサポートする音響シリーズです。5種類のヘアケア音響が含まれています。" }
)

