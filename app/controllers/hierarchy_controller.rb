class HierarchyController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @current_user = current_user
    @hierarchy_data = build_hierarchy_data(@current_user)
  end
  
  private
  
  def build_hierarchy_data(user)
    {
      user: user,
      children: user.referrals.includes(:level, :wott_level, :referrals).map do |child|
        build_hierarchy_data(child)
      end
    }
  end
end