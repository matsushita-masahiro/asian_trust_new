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

  private

  def product_params
    params.require(:product).permit(:name, :base_price, :is_active)
  end
end
