class Admin::PurchaseItemsController < Admin::BaseController
  before_action :set_purchase_item, only: [:edit, :update]

  def edit
    @purchase = @purchase_item.purchase
  end

  def update
    if @purchase_item.update(purchase_item_params)
      redirect_to admin_purchase_path(@purchase_item.purchase), notice: '商品情報を更新しました。'
    else
      @purchase = @purchase_item.purchase
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_purchase_item
    @purchase_item = PurchaseItem.find(params[:id])
  end

  def purchase_item_params
    params.require(:purchase_item).permit(:quantity, :unit_price)
  end
end