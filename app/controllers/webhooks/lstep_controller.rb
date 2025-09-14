# app/controllers/webhooks/lstep_controller.rb
class Webhooks::LstepController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    return head :unauthorized unless request.headers["X-LSTEP-SECRET"] == ENV["LSTEP_SECRET"]

    data = JSON.parse(request.body.read)
    referrer = User.find_by(lstep_user_id: data["referrer_id"])
    password = SecureRandom.hex(8)

    user = User.new(
      name: data["name"],
      email: data["email"],
      password: password,
      password_confirmation: password,
      lstep_user_id: data["user_id"],
      referred_by_id: referrer&.id,
      level_id: data["level_id"],
      confirmed_at: Time.current,
      status: 'active'
    )

    if user.save
      # Deviseのパスワード再設定トークンを発行し、メール送信
      token = user.send(:set_reset_password_token)
      UserMailer.send_password_reset_link(user, token).deliver_later

      render json: { status: "created" }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  
  def purchase
    return head :unauthorized unless request.headers["X-LSTEP-SECRET"] == ENV["LSTEP_SECRET"]
  
    data = JSON.parse(request.body.read)
  
    referrer = User.find_by(lstep_user_id: data["referrer_id"])
    product  = Product.find_by(id: data["product_id"])
  
    # Customerモデル削除により、buyerとしてUserを作成または検索
    buyer = User.find_or_create_by(email: data["customer_email"]) do |u|
      u.name = data["customer_name"]
      u.password = SecureRandom.hex(8)
      u.password_confirmation = u.password
      u.level_id = Level.find_by(name: 'お客様')&.id || 7
      u.status = 'active'
      u.confirmed_at = Time.current
    end
  
    Purchase.create!(
      user: referrer,
      buyer: buyer,
      quantity: data["quantity"],
      unit_price: data["unit_price"],
      price: data["quantity"] * product.base_price,
      purchased_at: Time.current
    )
  
    render json: { status: "created" }, status: :created
  end


  
  
end
