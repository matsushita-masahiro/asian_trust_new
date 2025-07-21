class Admin::ProductsController < Admin::BaseController
  def index
    @products = Product.order(:id)
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to admin_products_path, notice: "✅ 商品を更新しました"
    else
      render :edit, status: :unprocessable_entity
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
        :name, :base_price,
        product_prices_attributes: [:id, :level_id, :price, :_destroy]
      )
    end
    
    
end
