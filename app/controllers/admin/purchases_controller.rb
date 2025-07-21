class Admin::PurchasesController < Admin::BaseController
  before_action :set_purchase, only: [:edit, :update]
#   before_action :authenticate_purchase_creation, only: [:new, :create]

  def index
    @selected_month = params[:month] || Time.current.strftime('%Y-%m')
    
    # 月別の購入履歴を取得
    @purchases = Purchase.includes(:user, :product, :customer)
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

  def edit
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
    @users = User.all.order(:name, :email)
    @products = Product.all.order(:name)
  end

  def create
    # 顧客名から顧客を検索または作成
    customer_name = params[:purchase][:customer_name]
    customer = Customer.find_or_create_by(name: customer_name)
    
    # 購入情報を作成
    purchase_params = create_purchase_params.merge(customer_id: customer.id)
    @purchase = Purchase.new(purchase_params)
    
    if @purchase.save
      redirect_to admin_purchases_path, notice: '購入情報を作成しました。'
    else
      @users = User.all.order(:name, :email)
      @products = Product.all.order(:name)
      render :new, status: :unprocessable_entity
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
    params.require(:purchase).permit(:quantity, :unit_price)
  end

  def create_purchase_params
    params.require(:purchase).permit(:user_id, :product_id, :customer_id, :quantity, :unit_price, :purchased_at)
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