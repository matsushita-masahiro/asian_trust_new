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
    
    # 会社情報をinvoice_basesテーブルから取得（アジアビジネストラスト）
    # 管理者ユーザーのinvoice_baseを取得
    admin_user = User.find_by(admin: true)
    invoice_base = admin_user&.invoice_base
    
    # 請求先情報をinvoice_recipientsテーブルから取得
    company_info = admin_user&.invoice_recipients&.first
    
    # 関連データを明示的に読み込み
    @purchase.reload
    purchase_items = @purchase.purchase_items.includes(:product)

    if purchase_items.any?
      first_item = purchase_items.first
    end
    
    # 税計算（外税）
    total_with_tax = @purchase_invoice.total_amount
    subtotal = (total_with_tax / 1.1).to_i
    tax = total_with_tax - subtotal
    
    # 会社情報を直接設定
    if invoice_base
      company_name = invoice_base.company_name.presence || "株式会社アジアビジネストラスト"
      company_address = "#{invoice_base.postal_code.presence || '〒104-0061'} #{invoice_base.address.presence || '東京都中央区銀座4丁目6-1 銀座医科ビル3階'} "
      company_tel = invoice_base.tel.presence || "03-5904-8148"
      company_email = "Email: #{invoice_base.email.presence || 'abt1@asia-b-t.com'}"
      company_footer = "アジアビジネストラスト 事務局"
      registration_number = "T4210001009156"
      
      bank_name = invoice_base.bank_name.presence || "楽天銀行"
      bank_branch = invoice_base.bank_branch_name.presence || "第二営業支店"
      bank_branch_code = invoice_base.bank_branch_code.presence || "252"
      bank_account_type = invoice_base.bank_account_type.presence || "普通預金"
      bank_account_number = invoice_base.bank_account_number.presence || "7747552"
      bank_account_name = invoice_base.bank_account_name.presence || company_name
    else
      company_name = "株式会社アジアビジネストラスト"
      company_address = "〒104-0061 東京都中央区銀座4丁目6-1 銀座医科ビル3階"
      company_tel = "03-5904-8148"
      company_email = "abt1@asia-b-t.com"
      company_footer = "アジアビジネストラスト 事務局"
      registration_number = "T4210001009156"
      
      bank_name = "楽天銀行"
      bank_branch = "第二営業支店"
      bank_branch_code = "252"
      bank_account_type = "普通預金"
      bank_account_number = "7747552"
      bank_account_name = company_name
    end
    
    # 実際のテンプレートを使用してPDFを生成
    html_content = controller.render_to_string(
      template: 'order_mailer/purchase_invoice_pdf',
      layout: 'pdf',
      locals: {
        purchase_invoice: @purchase_invoice,
        purchase: @purchase,
        user: @purchase.user,
        invoice_base: invoice_base,
        company_info: company_info,
        purchase_items: purchase_items,
        total_with_tax: total_with_tax,
        subtotal: subtotal,
        tax: tax,
        company_name: company_name,
        company_address: company_address,
        company_tel: company_tel,
        company_email: company_email,
        company_footer: company_footer,
        registration_number: registration_number,
        bank_name: bank_name,
        bank_branch: bank_branch,
        bank_branch_code: bank_branch_code,
        bank_account_type: bank_account_type,
        bank_account_number: bank_account_number,
        bank_account_name: bank_account_name
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