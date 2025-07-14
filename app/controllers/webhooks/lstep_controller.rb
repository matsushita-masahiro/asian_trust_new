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
      level: data["level"],
      confirmed_at: Time.current
    )

    if user.save
      render json: { status: "created" }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
