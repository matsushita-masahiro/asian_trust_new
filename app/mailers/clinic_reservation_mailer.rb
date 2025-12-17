class ClinicReservationMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL'] || 'noreply@example.com'

  # クリニック予約確定メール
  def reservation_confirmed(clinic_reservation)
    @clinic_reservation = clinic_reservation
    @user = clinic_reservation.user
    @clinic = clinic_reservation.clinic
    @clinic_address = @clinic.user.addresses.find_by(address_type: 'registration')
    
    mail(
      to: @user.email,
      subject: "【Asia Business Trust】クリニック予約が確定しました - 予約番号: ##{@clinic_reservation.id}"
    )
  end

  # 緊急予約回答メール
  def emergency_response(purchase)
    @purchase = purchase
    @user = purchase.user
    
    # 配送先クリニック情報を取得
    delivery_info = purchase.delivery_informations.where(delivery_type: ['clinic', 'multiple']).first
    if delivery_info&.clinic_id.present?
      @clinic = Clinic.find_by(id: delivery_info.clinic_id)
      @clinic_address = @clinic&.user&.addresses&.find_by(address_type: 'registration')
    end
    
    mail(
      to: @user.email,
      subject: "【Asia Business Trust】緊急予約の回答が届きました - 購入ID: ##{@purchase.id}"
    )
  end
end
