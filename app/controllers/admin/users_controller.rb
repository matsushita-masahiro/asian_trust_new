# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::BaseController
  before_action :set_user
  before_action :set_selected_month_range

  def show
    @referrer_chain = @user.ancestors
    @referrals = @user.referrals

    # ✅ 自身の購入履歴（選択月）
    @purchases = @user.purchases.in_period(@selected_month_start, @selected_month_end)

    # ✅ 自身 + 下位の購入履歴（選択月）
    descendant_ids = @user.descendants.pluck(:id)
    @purchases_with_descendants = Purchase.where(user_id: [@user.id] + descendant_ids)
                                          .in_period(@selected_month_start, @selected_month_end)

    @total_sales_amount = @purchases_with_descendants.joins(:product).sum('products.base_price * purchases.quantity')

    # ✅ ref ごとの売上・ボーナスを算出
    @referral_stats = {}

    @referrals.each do |ref|
      # ref自身の購入（選択月）
      purchases = ref.purchases.in_period(@selected_month_start, @selected_month_end)
      sales = purchases.joins(:product).sum('products.base_price * purchases.quantity')

      # ✅ refに起因する全購入（その子孫含む）
      descendant_ids = ref.descendant_ids
      related_ids = [ref.id] + descendant_ids

      # ✅ ref経由で発生した全購入のうち、選択月に該当するもの
      descendant_purchases = Purchase
        .where(user_id: related_ids)
        .where(purchased_at: @selected_month_start..@selected_month_end)

      # ✅ @userにとってのボーナス合計（このrefツリーによるものだけ）
      bonus = descendant_purchases.sum { |p| @user.bonus_for_purchase(p) }

      @referral_stats[ref.id] = { sales: sales, bonus: bonus }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_selected_month_range
    selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month = selected_month
    @selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
    @selected_month_end   = Date.strptime(selected_month, "%Y-%m").end_of_month
  end
end
