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

  # 販売履歴表示
  def purchases
    @user = User.find(params[:id])

    unless can_access_user?(@user)
      redirect_to mypage_path, alert: "権限がありません。"
      return
    end

    @selected_month = params[:month] || Time.current.strftime('%Y-%m')
    
    # 指定ユーザーの販売履歴を取得
    @purchases = Purchase.includes(:product, :customer)
                        .where(user_id: @user.id)
                        .in_month_tokyo(@selected_month)
                        .order(purchased_at: :desc)
    
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
      
      # 自分の上位ユーザーで、かつ直接の紹介者の場合のみアクセス可能
      return true if user == current_user.referrer
      
      # その他の場合はアクセス不可
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
