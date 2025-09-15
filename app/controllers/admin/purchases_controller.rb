class Admin::PurchasesController < Admin::BaseController
  before_action :set_purchase, only: [:edit, :update, :confirm_payment]
#   before_action :authenticate_purchase_creation, only: [:new, :create]

  def index
    @selected_month = params[:month] || Time.current.strftime('%Y-%m')
    
    # 月別の購入履歴を取得
    @purchases = Purchase.includes(:user, :buyer, purchase_items: :product)
                        .in_month_tokyo(@selected_month)
                        .order(purchased_at: :desc)
    
    # ステータスでフィルタリング
    if params[:status] == 'pending'
      @purchases = @purchases.where(status: 'built')
    end
    
    # 統計情報
    @total_amount = @purchases.sum(&:total_price)
    @total_count = @purchases.count
    
    # 月選択用のオプション（過去12ヶ月分）
    @month_options = generate_month_options
    
    # 月名（日本語）
    @selected_month_name = Time.zone.parse("#{@selected_month}-01").strftime('%Y年%m月')
  end

  def edit
    # 複数商品の購入は編集不可
    if @purchase.purchase_items.count > 1
      redirect_to admin_purchases_path, alert: '複数商品を含む購入は編集できません。'
      return
    end
    
    # 編集画面で必要な情報を準備
  end

  def update
    if @purchase.update(purchase_params)
      redirect_to admin_purchases_path, notice: '購入履歴を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @purchase = Purchase.new
    @purchase.purchase_items.build  # 空のpurchase_itemを初期化
    @users = User.all.order(:name, :email)
    @products = Product.all.order(:name)
  end

  def create
    # 購入情報を作成
    @purchase = Purchase.new(
      user_id: params[:purchase][:user_id],
      buyer_id: params[:purchase][:buyer_id],
      purchased_at: params[:purchase][:purchased_at]
    )
    
    # 購入アイテムを作成
    @purchase.purchase_items.build(
      product_id: params[:purchase][:product_id],
      quantity: params[:purchase][:quantity],
      unit_price: params[:purchase][:unit_price]
    )
    
    if @purchase.save
      redirect_to admin_purchases_path, notice: '購入情報を作成しました。'
    else
      @users = User.all.order(:name, :email)
      @products = Product.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def confirm_payment
    if @purchase.built?
      @purchase.update!(status: 'paid')
      
      # 入金確認メールを送信
      begin
        OrderMailer.payment_confirmed(@purchase).deliver_now
        redirect_to admin_purchases_path, notice: '入金確認が完了しました。ステータスを「支払い完了」に変更し、お客様にメールを送信しました。'
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.message}"
        redirect_to admin_purchases_path, notice: '入金確認が完了しました。ステータスを「支払い完了」に変更しましたが、メール送信に失敗しました。'
      end
    else
      redirect_to edit_admin_purchase_path(@purchase), alert: 'この注文は既に入金確認済みです。'
    end
  end

  private

  def authenticate_purchase_creation
    authenticate_or_request_with_http_basic('購入情報作成') do |username, password|
      username == ENV['PURCHASE_ADMIN_USER'] && password == ENV['PURCHASE_ADMIN_PASSWORD']
    end
  end

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase).permit(purchase_items_attributes: [:id, :quantity, :unit_price])
  end

  def create_purchase_params
    params.require(:purchase).permit(:user_id, :buyer_id, :purchased_at, :product_id, :quantity, :unit_price)
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