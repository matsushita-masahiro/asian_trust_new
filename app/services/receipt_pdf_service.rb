class ReceiptPdfService
  include ApplicationHelper
  require 'digest'
  require 'set'
  
  def initialize(invoice)
    @invoice = invoice
  end

  def generate_and_upload_pdf
    Rails.logger.info "ReceiptPdfService: Starting PDF generation for Invoice #{@invoice.id}"
    
    begin
      # PDF生成
      pdf_content = generate_pdf
      Rails.logger.info "ReceiptPdfService: PDF generated successfully for Invoice #{@invoice.id}, size: #{pdf_content.bytesize} bytes"
      
      # S3にアップロード
      upload_to_s3(pdf_content)
      Rails.logger.info "ReceiptPdfService: PDF uploaded to S3 successfully for Invoice #{@invoice.id}"
      
      pdf_content
    rescue => e
      Rails.logger.error "ReceiptPdfService: Error in generate_and_upload_pdf for Invoice #{@invoice.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def generate_pdf
    # ApplicationControllerを使用してPDFを生成
    controller = ApplicationController.new
    controller.request = ActionDispatch::Request.new({})
    controller.response = ActionDispatch::Response.new
    
    html_content = controller.render_to_string(
      template: 'receipts/pdf_template',
      layout: 'pdf',
      locals: { 
        invoice: @invoice,
        bonus_details: get_bonus_details
      },
      formats: [:html]
    )
    
    WickedPdf.new.pdf_from_string(
      html_content,
      page_size: 'A4',
      margin: {
        top: 15,
        bottom: 15,
        left: 15,
        right: 15
      },
      encoding: 'UTF-8',
      disable_smart_shrinking: true,
      print_media_type: true,
      no_background: false,
      page_height: '297mm',
      page_width: '210mm'
    )
  end

  def upload_to_s3(pdf_content)
    filename = generate_filename
    Rails.logger.info "ReceiptPdfService: Uploading PDF to receipts bucket with filename: #{filename}"
    
    begin
      # 領収書専用のS3サービスを直接使用
      Rails.logger.info "ReceiptPdfService: Getting s3_receipts service"
      
      # 環境変数から直接設定を取得（より確実な方法）
      Rails.logger.info "ReceiptPdfService: Using environment variables for S3 configuration"
      
      access_key_id = ENV['AWS_ACCESS_KEY_ID']
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      region = ENV['AWS_REGION']
      bucket_name = ENV['AWS_RECEIPT_BUCKET']
      
      Rails.logger.info "ReceiptPdfService: Bucket name: #{bucket_name}"
      
      if access_key_id.present? && secret_access_key.present? && region.present? && bucket_name.present?
        # AWS S3クライアントを直接使用
        require 'aws-sdk-s3'
        
        s3_client = Aws::S3::Client.new(
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          region: region
        )
        # 該当月のフォルダに直接保存（例: 2025-08/filename.pdf）
        target_month = @invoice.target_month || Time.current.strftime("%Y-%m")
        key = "#{target_month}/#{filename}"
        
        Rails.logger.info "ReceiptPdfService: Uploading to bucket: #{bucket_name}, key: #{key}"
        
        # S3に直接アップロード
        s3_client.put_object(
          bucket: bucket_name,
          key: key,
          body: pdf_content,
          content_type: 'application/pdf',
          server_side_encryption: 'AES256'
        )
        
        Rails.logger.info "ReceiptPdfService: Direct S3 upload completed to #{bucket_name}"
        
        # Active Storageのblobを作成
        blob = ActiveStorage::Blob.create!(
          key: key,
          filename: filename,
          content_type: 'application/pdf',
          byte_size: pdf_content.bytesize,
          checksum: Digest::MD5.base64digest(pdf_content),
          service_name: 's3_receipts'
        )
        
        # Invoiceに添付
        @invoice.receipt_file.attach(blob)
        
        Rails.logger.info "ReceiptPdfService: PDF uploaded to receipts bucket successfully: #{filename}"
      else
        missing_vars = []
        missing_vars << "AWS_ACCESS_KEY_ID" unless access_key_id.present?
        missing_vars << "AWS_SECRET_ACCESS_KEY" unless secret_access_key.present?
        missing_vars << "AWS_REGION" unless region.present?
        missing_vars << "AWS_RECEIPT_BUCKET" unless bucket_name.present?
        
        raise "Missing environment variables: #{missing_vars.join(', ')}"
      end
      
    rescue => e
      Rails.logger.error "ReceiptPdfService: S3 upload failed for #{filename}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def generate_filename
    "receipt_#{@invoice.id}_#{@invoice.target_month}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf"
  end

  def get_bonus_details
    return [] unless @invoice.target_month.present?
    
    selected_month_start = Date.strptime(@invoice.target_month, "%Y-%m").beginning_of_month
    selected_month_end = Date.strptime(@invoice.target_month, "%Y-%m").end_of_month
    
    # InvoicePdfServiceと同じ計算ロジックを使用
    details = []
    user = @invoice.user
    
    # 自分の販売に対するボーナス
    self_purchases = user.purchases.includes(purchase_items: :product).where(purchased_at: selected_month_start..selected_month_end)
    
    self_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        bonus = user.bonus_for_purchase_item(item)
        
        if bonus > 0
          details << {
            type: '自己販売',
            user_name: user.name || user.email,
            product_name: item.product.name,
            quantity: item.quantity,
            unit_bonus: bonus / item.quantity,
            total_bonus: bonus,
            purchased_at: purchase.purchased_at,
            purchase_id: purchase.id
          }
        end
      end
    end
    
    # 子孫の販売に対するボーナス
    descendant_user_ids = user.descendant_ids.reject { |uid| uid == user.id }
    
    if descendant_user_ids.any?
      descendant_purchase_items = PurchaseItem.joins(:purchase)
                                             .where(purchases: { user_id: descendant_user_ids, purchased_at: selected_month_start..selected_month_end })
                                             .includes(:product, purchase: :user)

      descendant_purchase_items.each do |item|
        purchase = item.purchase
        purchase_user_level = purchase.user.level_at(purchase.purchased_at)
        my_level_at_purchase = user.level_at(purchase.purchased_at)
        
        product = item.product
        purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        
        if purchase_user_price > my_price
          diff = purchase_user_price - my_price
          bonus = diff * item.quantity
          
          if bonus > 0
            details << {
              type: '下位販売',
              user_name: purchase.user.name || purchase.user.email,
              product_name: item.product.name,
              quantity: item.quantity,
              unit_bonus: diff,
              total_bonus: bonus,
              purchased_at: purchase.purchased_at,
              purchase_id: purchase.id
            }
          end
        end
      end
    end
    
    # 直下の無資格者による販売に対するボーナス
    descendant_user_ids_set = Set.new(user.descendant_ids)
    
    user.referrals.reject(&:bonus_eligible?).each do |child|
      # 既に子孫として計算済みの場合はスキップ
      next if descendant_user_ids_set.include?(child.id)
      
      child_purchase_items = PurchaseItem.joins(:purchase)
                                        .where(purchases: { user_id: child.id, purchased_at: selected_month_start..selected_month_end })
                                        .includes(:product, purchase: :user)
      
      child_purchase_items.each do |item|
        purchase_date = item.purchase.purchased_at
        my_level_at_purchase = user.level_at(purchase_date)
        product = item.product
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        diff = base_price - my_price
        bonus = diff * item.quantity
        
        if bonus > 0
          details << {
            type: '無資格者販売',
            user_name: child.name || child.email,
            product_name: item.product.name,
            quantity: item.quantity,
            unit_bonus: diff,
            total_bonus: bonus,
            purchased_at: purchase_date,
            purchase_id: item.purchase.id
          }
        end
      end
    end

    sorted_details = details.sort_by { |d| d[:purchase_id] }
    
    Rails.logger.info "=== Receipt PDF Service Debug ==="
    Rails.logger.info "Total details found: #{sorted_details.count}"
    sorted_details.each_with_index do |detail, index|
      Rails.logger.info "#{index + 1}. Purchase ID: #{detail[:purchase_id]}, User: #{detail[:user_name]}, Amount: #{detail[:total_bonus]}"
    end
    Rails.logger.info "=== End Receipt PDF Service Debug ==="
    
    sorted_details
  end
end