# app/controllers/admin/inquiries_controller.rb
class Admin::InquiriesController < Admin::BaseController
  def index
    @inquiries = Inquiry.order(created_at: :desc)
  end

  def show
    @inquiry = Inquiry.find(params[:id])
  end
end
