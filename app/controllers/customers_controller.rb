class CustomersController < ApplicationController
  before_action :authenticate_user!

  def show
    @customer = Customer.find(params[:id])
    @purchases = @customer.purchases.includes(purchase_items: :product, user: []).order(purchased_at: :desc)
  end
end