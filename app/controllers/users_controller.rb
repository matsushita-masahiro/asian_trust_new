class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selected_month_range
  # 現在のユーザーのマイページ
  def mysales
    @user = current_user
  end

  # 下位ユーザーの詳細（再帰的に遷移可能）
  def show
    @user = User.find(params[:id])

    # アクセス権限チェック
    unless can_access_user?(@user)
      redirect_to mypage_path, alert: "権限がありません。"
      return
    end
  end

  # 販売履歴・購入履歴表示
  def purchases
    @user = User.find(params[:id])

    unless can_access_user?(@user)
      redirect_to mypage_path, alert: "権限がありません。"
      return
    end

    @selected_month = params[:month] || Time.current.strftime('%Y-%m')
    
    begin
      # URLパラメータで表示モードを判定
      # ?view=own_purchases が指定された場合は自分の購入履歴を表示
      if params[:view] == 'own_purchases'
        # 自分自身の購入履歴を表示（buyer_idが自分のユーザーIDと一致するもの）
        @purchases = Purchase.includes({ purchase_items: :product }, :buyer)
                            .where(buyer_id: @user.id)
                            .in_month_tokyo(@selected_month)
                            .order(purchased_at: :desc)
        @is_customer_view = true
        @is_own_purchases = true
      elsif @user.level.value == 6
        # お客様の場合：自分が購入者として記録された購入履歴を表示
        @purchases = Purchase.includes({ purchase_items: :product }, :buyer)
                            .where(buyer_id: @user.id)
                            .in_month_tokyo(@selected_month)
                            .order(purchased_at: :desc)
        @is_customer_view = true
        @is_own_purchases = false
      else
        # 指定ユーザーの販売履歴を取得（userとしての仲介）
        # 自分自身の購入は除外する（buyer_idが自分のユーザーIDと一致するものを除外）
        @purchases = Purchase.includes({ purchase_items: :product }, :buyer)
                            .where(user_id: @user.id)
                            .where.not(buyer_id: @user.id)
                            .in_month_tokyo(@selected_month)
                            .order(purchased_at: :desc)
        @is_customer_view = false
        @is_own_purchases = false
      end
    rescue => e
      Rails.logger.error "Error loading purchases: #{e.message}"
      @purchases = Purchase.none
      flash.now[:alert] = "購入履歴の読み込み中にエラーが発生しました。"
    end
    
    # 統計情報
    @total_amount = @purchases.sum(&:total_price)
    @total_count = @purchases.count
    
    # 月選択用のオプション（過去12ヶ月分）
    @month_options = generate_month_options
    
    # 月名（日本語）
    @selected_month_name = Time.zone.parse("#{@selected_month}-01").strftime('%Y年%m月')
  end
  
  private

    # ユーザーへのアクセス権限をチェック
    def can_access_user?(user)
      # 自分自身の場合はアクセス可能
      return true if user == current_user
      
      # 自分の下位ユーザーの場合はアクセス可能
      return true if current_user.descendants.include?(user)
      
      # 自分より上位のユーザーへのアクセスは禁止
      # （ただし、自分の祖先ユーザーで、かつ現在表示中のユーザーの上位にあたる場合は許可）
      if current_user.ancestors.include?(user)
        # 現在表示中のユーザーが自分の下位で、かつアクセス対象が現在ユーザーの上位の場合のみ許可
        current_displayed_user = User.find(params[:id]) rescue current_user
        return current_displayed_user.ancestors.include?(user) && current_user.descendants.include?(current_displayed_user)
      end
      
      false
    end

    def set_selected_month_range
      selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
      @selected_month = selected_month
      @selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
      @selected_month_end   = Date.strptime(selected_month, "%Y-%m").end_of_month
    end

    def generate_month_options
      options = []
      12.times do |i|
        date = Time.current.beginning_of_month - i.months
        value = date.strftime('%Y-%m')
        label = date.strftime('%Y年%m月')
        options << [label, value]
      end
      options
    end
end
