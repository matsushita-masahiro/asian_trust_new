class DebugController < ApplicationController
  def mailer_check
    methods = OrderMailer.instance_methods(false)
    
    render json: {
      order_mailer_methods: methods,
      has_bank_transfer_instructions: methods.include?(:bank_transfer_instructions),
      order_mailer_class: OrderMailer.to_s,
      rails_env: Rails.env
    }
  end
end