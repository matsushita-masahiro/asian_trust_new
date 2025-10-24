class Admin::AddressesController < Admin::BaseController
  before_action :set_user
  before_action :set_address, only: [:show, :edit, :update, :destroy]

  def create
    @address = @user.addresses.build(address_params)
    
    # 既存の同じタイプの住所があれば更新、なければ新規作成
    existing_address = @user.addresses.find_by(address_type: @address.address_type)
    
    if existing_address
      if existing_address.update(address_params.except(:address_type))
        render json: { 
          success: true, 
          message: "#{@address.address_type_label}を更新しました",
          address: format_address_response(existing_address)
        }
      else
        render json: { 
          success: false, 
          errors: existing_address.errors.full_messages 
        }
      end
    else
      if @address.save
        render json: { 
          success: true, 
          message: "#{@address.address_type_label}を登録しました",
          address: format_address_response(@address)
        }
      else
        render json: { 
          success: false, 
          errors: @address.errors.full_messages 
        }
      end
    end
  end

  def update
    if @address.update(address_params)
      render json: { 
        success: true, 
        message: "#{@address.address_type_label}を更新しました",
        address: format_address_response(@address)
      }
    else
      render json: { 
        success: false, 
        errors: @address.errors.full_messages 
      }
    end
  end

  def destroy
    address_type_label = @address.address_type_label
    @address.destroy
    render json: { 
      success: true, 
      message: "#{address_type_label}を削除しました" 
    }
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_address
    @address = @user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(:address_type, :postal_code, :address)
  end



  def format_address_response(address)
    {
      id: address.id,
      address_type: address.address_type,
      address_type_label: address.address_type_label,
      postal_code: address.postal_code,
      address: address.address,
      formatted_display: address_display_html(address)
    }
  end

  def address_display_html(address)
    html = ""
    if address.postal_code.present?
      html += "<small class='text-muted'>〒#{address.postal_code}</small><br>"
    end
    html += "<span class='address-text'>#{address.address}</span>"
    html.html_safe
  end
end