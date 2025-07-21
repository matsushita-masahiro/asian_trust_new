class Admin::BonusesController < Admin::BaseController
  def index
    @selected_month = params[:month].presence || Date.current.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month

    # ボーナス対象レベルのユーザーを取得
    bonus_eligible_users = User.joins(:level)
                              .where(levels: { name: User::BONUS_ELIGIBLE_LEVELS })
                              .includes(:level, :referrals, :purchases)

    @bonus_data = []

    bonus_eligible_users.each do |user|
      bonus_amount = user.bonus_in_period(@selected_month_start, @selected_month_end)
      
      if bonus_amount > 0
        @bonus_data << {
          user: user,
          bonus_amount: bonus_amount
        }
      end
    end

    # ボーナス額の降順でソート
    @bonus_data.sort_by! { |data| -data[:bonus_amount] }
  end
end