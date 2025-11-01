class Admin::ProductsController < Admin::BaseController
  def index
    @show_deleted = params[:show_deleted] == 'true'
    @category = params[:category]
    
    if @category.present?
      # 特定のカテゴリの商品を表示
      @products = @show_deleted ? 
        Product.deleted.where(category: @category).order(:id) : 
        Product.active.where(category: @category).order(:id)
    else
      # カテゴリ選択画面を表示
      @products = nil
    end
  end

  def edit
    # 価格情報も含めて取得（ビューでの％計算に必要）
    @product = Product.includes(:product_prices).find(params[:id])
    logger.debug("@product category =  #{@product.category}")
    
    # 価格情報を整理してビューに渡す
    if @product.category == 'wott'
      @price_data = prepare_wott_price_data(@product)
    elsif @product.category == 'ms' || @product.category == 'ag'
      @price_data = prepare_incentive_price_data(@product)
    else
      @price_data = prepare_standard_price_data(@product)
    end
  end

  def update
    @product = Product.includes(:product_prices).find(params[:id])
    if @product.update(product_params)
      redirect_to edit_admin_product_path(@product), notice: "✅ 商品を更新しました"
    else
      # エラー時も価格情報を含めて再取得
      @product.reload
      # 価格情報を整理してビューに渡す
      if @product.category == 'wott'
        @price_data = prepare_wott_price_data(@product)
      elsif @product.category == 'ms' || @product.category == 'ag'
        @price_data = prepare_incentive_price_data(@product)
      else
        @price_data = prepare_standard_price_data(@product)
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product = Product.find(params[:id])
    
    if @product.soft_delete
      redirect_to admin_products_path, notice: "✅ 商品を削除しました"
    else
      redirect_to admin_products_path, alert: "❌ 商品の削除に失敗しました"
    end
  end

  def restore
    @product = Product.find(params[:id])
    
    if @product.restore
      redirect_to admin_products_path, notice: "✅ 商品を復元しました"
    else
      redirect_to admin_products_path(show_deleted: true), alert: "❌ 商品の復元に失敗しました"
    end
  end

  def price_info
    @product = Product.find(params[:id])
    
    # 基本価格を返す（最も高い価格として使用）
    price = @product.base_price || 0
    
    render json: {
      id: @product.id,
      name: @product.name,
      base_price: price,
      unit_quantity: @product.unit_quantity,
      unit_label: @product.unit_label,
      display_unit: @product.display_unit
    }
  end

  private

    def product_params
      params.require(:product).permit(
        :name, :short_name, :base_price, :unit_quantity, :unit_label,
        product_prices_attributes: [:id, :level_id, :wott_level_id, :price, :incentive_rate, :incentive_percentage, :_destroy]
      )
    end
    
    def prepare_wott_price_data(product)
      base_price = product.base_price || 1100000
      
      WottLevel.ordered.map do |wott_level|
        price_record = product.product_prices.find { |pp| pp.wott_level_id == wott_level.id } || 
                      product.product_prices.build(wott_level: wott_level)
        
        # インセンティブ受給対象かどうか
        has_incentive = ['総代理店', '代理店', 'サポーター'].include?(wott_level.name)
        
        # デフォルトインセンティブ率
        default_rate = case wott_level.name
        when '総代理店'
          20
        when '代理店'
          10
        when 'サポーター'
          5
        else
          0
        end
        
        # 実際のインセンティブ率（DBから取得）
        actual_rate = price_record.incentive_percentage || default_rate
        
        # インセンティブ額の計算
        incentive_amount = has_incentive ? (base_price * (actual_rate / 100.0)).to_i : 0
        
        {
          level: wott_level,
          price_record: price_record,
          default_rate: default_rate,
          has_incentive: has_incentive,
          actual_rate: actual_rate,
          incentive_amount: incentive_amount,
          base_price: base_price
        }
      end
    end
    
    def prepare_incentive_price_data(product)
      base_price = product.base_price || 0
      
      Level.all.order(:value).map do |level|
        price_record = product.product_prices.find { |pp| pp.level_id == level.id } || 
                      product.product_prices.build(level: level)
        
        # インセンティブ受給対象かどうか
        has_incentive = ['総代理店', '代理店', 'アドバイザー', 'サポーター'].include?(level.name)
        
        # デフォルトインセンティブ率
        default_rate = case level.name
        when '総代理店'
          20
        when '代理店'
          15
        when 'アドバイザー'
          10
        when 'サポーター'
          5
        else
          0
        end
        
        # 実際のインセンティブ率（DBから取得）
        actual_rate = price_record.incentive_rate || default_rate
        
        {
          level: level,
          price_record: price_record,
          default_rate: default_rate,
          has_incentive: has_incentive,
          actual_rate: actual_rate,
          base_price: base_price
        }
      end
    end
    
    def prepare_standard_price_data(product)
      Level.all.map do |level|
        price_record = product.product_prices.find { |pp| pp.level_id == level.id } || 
                      product.product_prices.build(level: level)
        
        {
          level: level,
          price_record: price_record
        }
      end
    end
    
    def calculate_wott_default_incentive(level_symbol)
      case level_symbol
      when :special_agent
        220000
      when :agent
        165000
      when :supporter
        55000
      else
        0
      end
    end
    
    def calculate_ms_default_incentive(level_name, base_price)
      case level_name
      when '総代理店'
        (base_price * 0.80).to_i  # 20%割引 = 80%の価格
      when '代理店'
        (base_price * 0.85).to_i  # 15%割引 = 85%の価格
      when 'アドバイザー'
        (base_price * 0.90).to_i  # 10%割引 = 90%の価格
      when 'サポーター'
        (base_price * 0.95).to_i  # 5%割引 = 95%の価格
      else
        base_price  # 割引なし
      end
    end
end
