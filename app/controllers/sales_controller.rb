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
                   .includes(purchase_items: :product, user: [])
                   .where(user_id: user_ids)
                   .where(purchased_at: start_date..end_date)
                   .order(purchased_at: :desc)

    # ✅ 合計金額と合計ボーナス（購入者単価×数量で計算）
    @total_sum = @purchases.sum { |purchase| purchase.purchase_items.sum { |item| item.seller_price * item.quantity } }
    
    # ✅ 合計ボーナス（アイテム別計算でビューと統一）
    @total_bonus = 0
    @purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        if item.product.category == 'wott'
          # WOTT商品の場合：購入者自身のインセンティブを計算
          if purchase.user.has_wott_level?
            wott_level = purchase.user.wott_level
            incentive_record = item.product.product_prices.find_by(wott_level: wott_level)
            if incentive_record&.price
              incentive_unit = (item.product.base_price || 0) - incentive_record.price
              item_bonus = incentive_unit > 0 ? incentive_unit * item.quantity : 0
            else
              item_bonus = 0
            end
          else
            item_bonus = 0
          end
        else
          # 通常商品の場合
          if purchase.user == @user
            item_bonus = 0  # 自己購入インセンティブは廃止
          else
            item_bonus = @user.bonus_for_purchase_item(item)
          end
        end
        @total_bonus += item_bonus
      end
    end
    
    # ✅ ユーザーの商品単価情報を取得
    @user_product_prices = get_user_product_prices(@user)
  end


  def show
    @user = current_user

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
                   .includes(purchase_items: :product, user: [])
                   .where(user_id: user_ids)
                   .where(purchased_at: start_date..end_date)
                   .order(purchased_at: :desc)

    # ✅ 合計金額と合計ボーナス
    @total_sum = @purchases.sum(&:total_price)
    
    # ✅ 合計ボーナス（アイテム別計算でビューと統一）
    @total_bonus = 0
    @purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        if item.product.category == 'wott'
          # WOTT商品の場合：購入者自身のインセンティブを計算
          if purchase.user.has_wott_level?
            wott_level = purchase.user.wott_level
            incentive_record = item.product.product_prices.find_by(wott_level: wott_level)
            if incentive_record&.price
              incentive_unit = (item.product.base_price || 0) - incentive_record.price
              item_bonus = incentive_unit > 0 ? incentive_unit * item.quantity : 0
            else
              item_bonus = 0
            end
          else
            item_bonus = 0
          end
        else
          # 通常商品の場合
          if purchase.user == @user
            item_bonus = 0  # 自己購入インセンティブは廃止
          else
            item_bonus = @user.bonus_for_purchase_item(item)
          end
        end
        @total_bonus += item_bonus
      end
    end
  end
  
  private
  
  def get_user_product_prices(user)
    # アクティブな商品のみを取得
    products = Product.active.order(:id)
    user_level = user.level
    
    products.map do |product|
      product_price = ProductPrice.find_by(product: product, level: user_level)
      {
        product: product,
        price: product_price&.price || product.base_price
      }
    end
  end
end
