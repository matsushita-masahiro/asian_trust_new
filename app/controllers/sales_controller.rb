class SalesController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = User.find(params[:user_id])

    # ✅ アクセス制限：自分自身または下位ユーザーのみ閲覧可
    unless current_user == @user || @user.ancestors.include?(current_user)
      redirect_to root_path, alert: "アクセス権がありません"
      return
    end

    # ✅ 選択された月（YYYY-MM形式）を取得。なければ今月。
    selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month = selected_month
    start_date = Date.strptime(selected_month, "%Y-%m").beginning_of_month.beginning_of_day
    end_date   = Date.strptime(selected_month, "%Y-%m").end_of_month.end_of_day

    # ✅ 対象ユーザーとその下位の全ID
    user_ids = [@user.id] + @user.descendant_ids

    # ✅ 該当月の購入データを取得（N+1防止のincludes）
    @purchases = Purchase
                   .includes(:product, :customer, :user)
                   .where(user_id: user_ids)
                   .where(purchased_at: start_date..end_date)
                   .order(purchased_at: :desc)

    # ✅ 各購入に対するボーナスを計算してマップ化（View用）
    @purchase_bonus_map = @purchases.index_with do |purchase|
      @user.bonus_for_purchase(purchase)
    end

    # ✅ 合計金額と合計ボーナス
    @total_sum = @purchases.sum(&:total_price)
    @total_bonus = @purchase_bonus_map.values.sum
  end
end
