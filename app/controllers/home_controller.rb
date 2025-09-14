class HomeController < ApplicationController
  
  def index
    # Deviseのヘルパーメソッドが利用可能かテスト
    Rails.logger.info "user_signed_in? method available: #{respond_to?(:user_signed_in?)}"
  end
  
  def law
  end
  
  def privacy
  end

  def terms
  end
  
end
