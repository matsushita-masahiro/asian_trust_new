class ReceiptPdfService
  include ApplicationHelper
  require 'digest'
  require 'set'
  require 'tempfile'
  
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
        user: @invoice.user,
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
      bucket_name = ENV['AWS_INCENTIVE_RECEIPT_BUCKET']
      
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
        
        # Active Storageを使用してS3にアップロード
        # 一時ファイルを作成
        temp_file = Tempfile.new([filename.gsub('.pdf', ''), '.pdf'])
        temp_file.binmode
        temp_file.write(pdf_content)
        temp_file.rewind
        
        # Active Storageを使用してアップロード
        @invoice.receipt_file.attach(
          io: temp_file,
          filename: filename,
          content_type: 'application/pdf'
        )
        
        temp_file.close
        temp_file.unlink
        
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
    
    # InvoicesControllerと同じ正確な計算ロジックを使用
    details = []
    user = @invoice.user
    
    # 自分と下位ユーザーの販売に対するボーナス（sales/index.html.erbと同じ）
    user_ids = [user.id] + user.descendant_ids
    all_purchases = Purchase.includes(purchase_items: :product, user: [])
                           .where(user_id: user_ids)
                           .where(purchased_at: selected_month_start..selected_month_end)
    
    all_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        # 自己販売に対するインセンティブ計算
        item_bonus = user.bonus_for_purchase_item(item)
        unit_bonus = user.incentive_unit_price_for_item(item)
        
        if item_bonus > 0
          # 種別を判定
          purchase_type = if purchase.user == user
                           '自己販売'
                         else
                           '下位販売'
                         end
          
          details << {
            type: purchase_type,
            user_name: purchase.user.name || purchase.user.email,
            product_name: item.product.name,
            quantity: item.quantity,
            unit_bonus: unit_bonus,     # インセンティブ単価
            total_bonus: item_bonus,    # 合計インセンティブ
            purchased_at: purchase.purchased_at,
            purchase_id: purchase.id
          }
        end
      end
    end

    sorted_details = details.sort_by { |d| d[:purchase_id] }
    
    Rails.logger.info "=== Receipt PDF Service Debug ==="
    Rails.logger.info "Total details found: #{sorted_details.count}"
    sorted_details.each_with_index do |detail, index|
      Rails.logger.info "#{index + 1}. Purchase ID: #{detail[:purchase_id]}, User: #{detail[:user_name]}, Unit: #{detail[:unit_bonus]}, Total: #{detail[:total_bonus]}"
    end
    Rails.logger.info "=== End Receipt PDF Service Debug ==="
    
    sorted_details
  end
end