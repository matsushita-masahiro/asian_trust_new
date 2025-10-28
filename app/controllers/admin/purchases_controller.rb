class Admin::PurchasesController < Admin::BaseController
  before_action :set_purchase, only: [:show, :edit, :update, :confirm_payment]
#   before_action :authenticate_purchase_creation, only: [:new, :create]

  def index
    @selected_month = params[:month] || Time.current.strftime('%Y-%m')
    
    # 月別の購入履歴を取得
    @purchases = Purchase.includes(:user, purchase_items: :product)
                        .in_month_tokyo(@selected_month)
                        .order(purchased_at: :desc)
    
    # ステータスでフィルタリング
    if params[:status] == 'pending'
      @purchases = @purchases.where(status: 'built')
    end
    
    # 統計情報（税込み金額で計算）
    @total_amount = @purchases.sum do |purchase|
      if purchase.purchase_invoice&.total_with_tax.present? && purchase.purchase_invoice.total_with_tax > 0
        purchase.purchase_invoice.total_with_tax
      else
        # 従来の計算方法（税込み）
        seller_price_total = purchase.purchase_items.sum { |item| item.quantity * item.unit_price }
        shipping_fee = purchase.total_shipping_fees
        admin_fee = purchase.purchase_invoice&.admin_fee || 0
        subtotal_before_tax = seller_price_total + shipping_fee + admin_fee
        tax_amount = (subtotal_before_tax * 0.1).round  # 消費税10%
        subtotal_before_tax + tax_amount
      end
    end
    @total_count = @purchases.count
    
    # 未入金購入分の合計金額を計算（税込み）
    @pending_amount = @purchases.where(status: 'built').sum do |purchase|
      if purchase.purchase_invoice&.total_with_tax.present? && purchase.purchase_invoice.total_with_tax > 0
        purchase.purchase_invoice.total_with_tax
      else
        seller_price_total = purchase.purchase_items.sum { |item| item.quantity * item.unit_price }
        shipping_fee = purchase.total_shipping_fees
        admin_fee = purchase.purchase_invoice&.admin_fee || 0
        subtotal_before_tax = seller_price_total + shipping_fee + admin_fee
        tax_amount = (subtotal_before_tax * 0.1).round
        subtotal_before_tax + tax_amount
      end
    end
    
    # 入金済み購入分の合計金額を計算（税込み）
    @paid_amount = @purchases.where(status: ['paid', 'reserved']).sum do |purchase|
      if purchase.purchase_invoice&.total_with_tax.present? && purchase.purchase_invoice.total_with_tax > 0
        purchase.purchase_invoice.total_with_tax
      else
        seller_price_total = purchase.purchase_items.sum { |item| item.quantity * item.unit_price }
        shipping_fee = purchase.total_shipping_fees
        admin_fee = purchase.purchase_invoice&.admin_fee || 0
        subtotal_before_tax = seller_price_total + shipping_fee + admin_fee
        tax_amount = (subtotal_before_tax * 0.1).round
        subtotal_before_tax + tax_amount
      end
    end
    
    # 月選択用のオプション（過去12ヶ月分）
    @month_options = generate_month_options
    
    # 月名（日本語）
    @selected_month_name = Time.zone.parse("#{@selected_month}-01").strftime('%Y年%m月')
  end

  def show
    # 複数商品の購入詳細画面
    # purchase_itemsを再読み込みして最新の値を取得
    @purchase.reload
  end

  def edit
    # 複数商品の購入は詳細画面に遷移
    if @purchase.purchase_items.count > 1
      redirect_to admin_purchase_path(@purchase)
      return
    end
    
    # 編集画面で必要な情報を準備
  end

  def update
    if @purchase.update(purchase_params)
      # 購入月を取得してリダイレクト先に含める
      purchase_month = @purchase.purchased_at.strftime('%Y-%m')
      redirect_to admin_purchases_path(month: purchase_month), notice: '購入履歴を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @purchase = Purchase.new
    @purchase.purchase_items.build  # 空のpurchase_itemを初期化
    # お客様レベルを除外したユーザーリストを取得（販売店用）
    @sellers = User.joins(:level).where.not(levels: { name: 'お客様' }).order(:name, :email)
    # 全ユーザーリスト（購入者用）
    @buyers = User.all.order(:name, :email)
    @products = Product.active.order(:name)
    
    # 数を計算
    @sellers_count = @sellers.count
    @buyers_count = @buyers.count
  end

  def create
    # 購入情報を作成
    @purchase = Purchase.new(
      user_id: params[:purchase][:user_id],
      purchased_at: params[:purchase][:purchased_at]
    )
    
    # 購入者とその商品を取得
    user = User.find(params[:purchase][:user_id])
    product = Product.find(params[:purchase][:product_id])
    
    # 購入者のレベルに応じたseller_priceを取得
    seller_price = if user.level
      product.price_for(user.level.symbol) || 0
    else
      0
    end
    
    # 購入アイテムを作成
    @purchase.purchase_items.build(
      product_id: params[:purchase][:product_id],
      quantity: params[:purchase][:quantity],
      unit_price: params[:purchase][:unit_price],
      seller_price: seller_price
    )
    
    if @purchase.save
      redirect_to admin_purchases_path, notice: '購入情報を作成しました。'
    else
      # お客様レベルを除外したユーザーリストを取得（販売店用）
      @sellers = User.joins(:level).where.not(levels: { name: 'お客様' }).order(:name, :email)
      # 全ユーザーリスト（購入者用）
      @buyers = User.all.order(:name, :email)
      @products = Product.active.order(:name)
      
      # 数を計算
      @sellers_count = @sellers.count
      @buyers_count = @buyers.count
      
      render :new, status: :unprocessable_entity
    end
  end

  def confirm_payment
    if @purchase.built?
      @purchase.update!(status: 'paid')
      
      # 購入月を取得してリダイレクト先に含める
      purchase_month = @purchase.purchased_at.strftime('%Y-%m')
      
      # 入金確認メールを送信
      begin
        OrderMailer.payment_confirmed(@purchase).deliver_now
        redirect_to admin_purchases_path(month: purchase_month), notice: '入金確認が完了しました。ステータスを「支払済み」に変更し、お客様にメールを送信しました。'
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.message}"
        redirect_to admin_purchases_path(month: purchase_month), notice: '入金確認が完了しました。ステータスを「支払済み」に変更しましたが、メール送信に失敗しました。'
      end
    else
      redirect_to edit_admin_purchase_path(@purchase), alert: 'この注文は既に入金確認済みです。'
    end
  end

  # 購入者とレベルに応じた商品価格を取得するAPI
  def get_user_level_price
    user = User.find(params[:user_id])
    product = Product.find(params[:product_id])
    
    price = if user.level
      product.price_for(user.level.symbol) || 0
    else
      0
    end
    
    render json: { 
      price: price,
      level_name: user.level&.name || '未設定',
      user_name: user.display_name
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
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
    params.require(:purchase).permit(:user_id, :purchased_at, :product_id, :quantity, :unit_price, :seller_price)
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