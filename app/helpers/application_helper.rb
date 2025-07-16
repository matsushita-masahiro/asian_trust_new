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
end
