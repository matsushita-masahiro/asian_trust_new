# クリニック情報を登録するfixture

class ClinicFixture
  def self.create_clinics
    puts "🏥 Creating clinic users and invoice_base data..."
    
    # クリニックレベルを取得
    clinic_level = Level.find_by(name: 'クリニック')
    if clinic_level.nil?
      puts "❌ Clinic level not found. Please run levels fixture first."
      return
    end
    
    # クリニック情報の配列
    clinics_data = [
      {
        name: "銀座中央クリニック",
        postal_code: "104-0061",
        address: "東京都中央区銀座７丁目８−８ Isgビル 7F",
        phone: "03-6280-6901",
        email: "ginze-central-clinic@example.com"
      },
      {
        name: "ティファクリニック大宮院",
        postal_code: "330-0844",
        address: "埼玉県さいたま市大宮区下町１丁目４５ 松亀センタービル 1F",
        phone: "048-788-5926",
        email: "tifa-omiya@example.com"
      },
      {
        name: "ティファクリニック横浜院",
        postal_code: "220-0004",
        address: "神奈川県横浜市西区北幸1-1-8 エキニア横浜 7F 705",
        phone: "045-509-1932",
        email: "tifa-yokohama@example.com"
      },
      {
        name: "ティファクリニック新宿東口院",
        postal_code: "160-0022",
        address: "東京都新宿区新宿3-21-6 龍生堂ビル 7F",
        phone: "03-6416-0193",
        email: "tifa-shinjuku-east@example.com"
      }
    ]
    
    created_count = 0
    
    clinics_data.each_with_index do |clinic_data, index|
      begin
        # ユーザーを作成または更新
        user = User.find_or_initialize_by(email: clinic_data[:email])
        user.assign_attributes(
          name: clinic_data[:name],
          phone: clinic_data[:phone],
          level_id: clinic_level.id,
          password: "clinic_password_#{index + 1}",
          confirmed_at: Time.current
        )
        
        if user.save
          puts "✅ Created/Updated user: #{user.name} (#{user.email})"
          
          # invoice_baseを作成または更新
          invoice_base = user.invoice_base || user.build_invoice_base
          invoice_base.assign_attributes(
            company_name: clinic_data[:name],
            postal_code: clinic_data[:postal_code],
            address: clinic_data[:address],
            email: clinic_data[:email]
          )
          
          if invoice_base.save
            puts "✅ Created/Updated invoice_base for: #{clinic_data[:name]}"
            created_count += 1
          else
            puts "❌ Failed to create invoice_base for #{clinic_data[:name]}: #{invoice_base.errors.full_messages.join(', ')}"
          end
        else
          puts "❌ Failed to create user #{clinic_data[:name]}: #{user.errors.full_messages.join(', ')}"
        end
        
      rescue => e
        puts "❌ Error creating clinic #{clinic_data[:name]}: #{e.message}"
      end
    end
    
    puts "🏥 Clinic creation completed! Created/Updated #{created_count} clinics"
  end
end

# fixtureデータを作成
ClinicFixture.create_clinics