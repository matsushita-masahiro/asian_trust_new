module ApplicationHelper
    
    def month_options
        start_month = Date.new(2025, 4, 1)
        today = Date.today
        months = []
    
        while start_month <= today
          months << [start_month.strftime("%Y年%-m月度"), start_month.strftime("%Y-%m")]
          start_month = start_month.next_month
        end
    
        months.reverse # 新しい順
     end

     def format_postal_code(postal_code)
      postal_code.to_s.insert(3, '-')
     end

     # 消費税率を取得
     def tax_rate
       ENV.fetch('TAX_RATE', '0.1').to_f
     end

     # 消費税率をパーセント表示で取得
     def tax_rate_percentage
       (tax_rate * 100).to_i
     end

     # 消費税を計算
     def calculate_tax(amount)
       (amount.to_f * tax_rate).to_i
     end

     # 税込み金額を計算
     def calculate_total_with_tax(amount)
       amount.to_i + calculate_tax(amount)
     end

     # 階層図用: 全下位ユーザー数を再帰的に計算
     def count_all_descendants(user)
       count = user.referrals.count
       user.referrals.each do |child|
         count += count_all_descendants(child)
       end
       count
     end

     # 階層図用: 階層データを構築
     def build_hierarchy_node(user)
       {
         user: user,
         children: user.referrals.includes(:level, :wott_level, :referrals).map do |child|
           build_hierarchy_node(child)
         end
       }
     end
    
end
