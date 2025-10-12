class PurchaseInvoicePdfService
  include ApplicationHelper
  require 'digest'
  
  def initialize(purchase_invoice)
    @purchase_invoice = purchase_invoice
    @purchase = purchase_invoice.purchase
  end

  def generate_and_upload_pdf
    Rails.logger.info "PurchaseInvoicePdfService: Starting PDF generation for PurchaseInvoice #{@purchase_invoice.id}"
    
    # PDF生成
    pdf_content = generate_pdf
    Rails.logger.info "PurchaseInvoicePdfService: PDF generated successfully for PurchaseInvoice #{@purchase_invoice.id}, size: #{pdf_content.bytesize} bytes"
    
    # S3にアップロード
    upload_to_s3(pdf_content)
    Rails.logger.info "PurchaseInvoicePdfService: PDF uploaded to S3 successfully for PurchaseInvoice #{@purchase_invoice.id}"
    
    pdf_content
  end

  private

  def generate_pdf
    # ApplicationControllerを使用してPDFを生成
    controller = ApplicationController.new
    controller.request = ActionDispatch::Request.new({})
    controller.response = ActionDispatch::Response.new
    
    # 会社情報をDBから取得
    admin_user = User.find_by(admin: true)
    invoice_base = admin_user&.invoice_base
    
    # 購入商品情報を取得（関連データを含む）
    purchase_items = @purchase.purchase_items.includes(:product)
    
    # Buyerを明示的に読み込み
    buyer = @purchase.buyer
    
    Rails.logger.info "Buyer loaded: #{buyer&.name || 'No name'}"
    Rails.logger.info "First item product name: #{purchase_items.first&.product&.name || 'No product name'}"
    
    # 税計算（外税）
    total_with_tax = @purchase_invoice.total_amount
    subtotal = (total_with_tax / 1.1).to_i
    tax = total_with_tax - subtotal
    
    # デバッグ情報をログ出力
    Rails.logger.info "=== PurchaseInvoicePdfService Debug ==="
    Rails.logger.info "Purchase Invoice ID: #{@purchase_invoice.id}"
    Rails.logger.info "Purchase ID: #{@purchase.id}"
    Rails.logger.info "Buyer: #{@purchase.buyer&.name || 'nil'}"
    Rails.logger.info "Invoice Base present: #{invoice_base.present?}"
    Rails.logger.info "Purchase Items count: #{purchase_items.count}"
    Rails.logger.info "Total with tax: #{total_with_tax}"
    Rails.logger.info "Subtotal: #{subtotal}"
    Rails.logger.info "Tax: #{tax}"
    
    # デバッグ用の簡単なHTMLを生成してテスト
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Test Invoice</title>
      </head>
      <body>
        <h1>請求書テスト</h1>
        <p>Purchase Invoice ID: #{@purchase_invoice.id}</p>
        <p>Purchase ID: #{@purchase.id}</p>
        <p>Buyer: #{buyer&.name || 'No buyer name'}</p>
        <p>Invoice Number: #{@purchase_invoice.invoice_number}</p>
        <p>Total Amount: #{@purchase_invoice.total_amount}</p>
        <p>Purchase Items Count: #{purchase_items.count}</p>
        <h2>商品明細</h2>
        <ul>
          #{purchase_items.map { |item| "<li>#{item.product&.name || 'No product name'} - 数量: #{item.quantity} - 単価: #{item.unit_price}</li>" }.join}
        </ul>
        <p>会社情報: #{invoice_base ? 'あり' : 'なし'}</p>
        <p>Total with tax: #{total_with_tax}</p>
        <p>Subtotal: #{subtotal}</p>
        <p>Tax: #{tax}</p>
      </body>
      </html>
    HTML
    
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
    Rails.logger.info "PurchaseInvoicePdfService: Uploading PDF to S3 purchase_invoices bucket with filename: #{filename}"
    
    begin
      # 環境変数から直接設定を取得
      Rails.logger.info "PurchaseInvoicePdfService: Using environment variables for S3 configuration"
      
      access_key_id = ENV['AWS_ACCESS_KEY_ID']
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      region = ENV['AWS_REGION']
      bucket_name = ENV['AWS_PURCHASE_INVOICE_BUCKET'] || ENV['AWS_INVOICE_BUCKET'] # フォールバック
      
      Rails.logger.info "PurchaseInvoicePdfService: Bucket name: #{bucket_name}"
      
      if access_key_id.present? && secret_access_key.present? && region.present? && bucket_name.present?
        # AWS S3クライアントを直接使用
        require 'aws-sdk-s3'
        
        s3_client = Aws::S3::Client.new(
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          region: region
        )
        
        # 該当月のフォルダに直接保存（例: 2025-08/filename.pdf）
        target_month = @purchase.purchased_at.strftime("%Y-%m")
        key = "purchase_invoices/#{target_month}/#{filename}"
        
        Rails.logger.info "PurchaseInvoicePdfService: Uploading to bucket: #{bucket_name}, key: #{key}"
        
        # S3に直接アップロード
        s3_client.put_object(
          bucket: bucket_name,
          key: key,
          body: pdf_content,
          content_type: 'application/pdf',
          server_side_encryption: 'AES256'
        )
        
        Rails.logger.info "PurchaseInvoicePdfService: Direct S3 upload completed to #{bucket_name}"
        
        # Active Storageのblobを作成
        blob = ActiveStorage::Blob.create!(
          key: key,
          filename: filename,
          content_type: 'application/pdf',
          byte_size: pdf_content.bytesize,
          checksum: Digest::MD5.base64digest(pdf_content),
          service_name: 's3_invoices'
        )
        
        # PurchaseInvoiceに添付
        @purchase_invoice.pdf_file.attach(blob)
        
        Rails.logger.info "PurchaseInvoicePdfService: PDF uploaded to purchase_invoices bucket successfully: #{filename}"
      else
        missing_vars = []
        missing_vars << "AWS_ACCESS_KEY_ID" unless access_key_id.present?
        missing_vars << "AWS_SECRET_ACCESS_KEY" unless secret_access_key.present?
        missing_vars << "AWS_REGION" unless region.present?
        missing_vars << "AWS_PURCHASE_INVOICE_BUCKET or AWS_INVOICE_BUCKET" unless bucket_name.present?
        
        raise "Missing environment variables: #{missing_vars.join(', ')}"
      end
      
    rescue => e
      Rails.logger.error "PurchaseInvoicePdfService: S3 upload failed for #{filename}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def generate_filename
    "purchase_invoice_#{@purchase_invoice.id}_#{@purchase.purchased_at.strftime('%Y%m')}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf"
  end
end