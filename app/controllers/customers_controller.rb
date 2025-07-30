class CustomersController < ApplicationController
  before_action :authenticate_user!

  def show
    @customer = Customer.find(params[:id])
    @purchases = @customer.purchases.includes(:product, :user).order(purchased_at: :desc)
  end
end