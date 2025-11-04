class PurchaseReceiptPdfService
  def initialize(purchase_invoice)
    @purchase_invoice = purchase_invoice
  end

  def generate_and_upload_pdf
    Rails.logger.info "=== Starting receipt PDF generation for PurchaseInvoice #{@purchase_invoice.id} ==="
    Rails.logger.info "Invoice number: #{@purchase_invoice.invoice_number}"
    
    # HTMLテンプレートからPDFを生成
    Rails.logger.info "Rendering HTML template..."
    
    # 発行者情報を取得（user_id=1のInvoiceRecipient）
    invoice_recipient = InvoiceRecipient.find_by(user_id: 1)
    
    # コントローラーのコンテキストでレンダリング
    controller = ApplicationController.new
    controller.instance_variable_set(:@purchase_invoice, @purchase_invoice)
    controller.instance_variable_set(:@invoice_recipient, invoice_recipient)
    
    html = controller.render_to_string(
      template: 'purchase_invoices/pdf_receipt',
      layout: 'pdf'
    )
    Rails.logger.info "HTML template rendered successfully"
    
    Rails.logger.info "Generating PDF from HTML..."
    pdf_content = WickedPdf.new.pdf_from_string(html)
    Rails.logger.info "PDF generated successfully, size: #{pdf_content.bytesize} bytes"
    
    # S3にアップロード
    Rails.logger.info "Uploading PDF to S3..."
    upload_to_s3(pdf_content)
    
    Rails.logger.info "Receipt PDF generated and uploaded successfully for PurchaseInvoice #{@purchase_invoice.id}"
    
    pdf_content
  end

  private

  def upload_to_s3(pdf_content)
    # S3クライアントの初期化
    s3_client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'] || 'ap-northeast-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    
    bucket_name = ENV['AWS_PURCHASE_RECEIPT_BUCKET']
    file_key = "receipts/#{@purchase_invoice.invoice_number}-receipt.pdf"
    
    Rails.logger.info "Uploading receipt PDF to S3: bucket=#{bucket_name}, key=#{file_key}"
    
    # S3にアップロード
    s3_client.put_object(
      bucket: bucket_name,
      key: file_key,
      body: pdf_content,
      content_type: 'application/pdf',
      metadata: {
        'invoice_id' => @purchase_invoice.id.to_s,
        'invoice_number' => @purchase_invoice.invoice_number,
        'generated_at' => Time.current.iso8601
      }
    )
    
    # Active Storageにも保存（オプション）
    @purchase_invoice.receipt_file.attach(
      io: StringIO.new(pdf_content),
      filename: "領収書_#{@purchase_invoice.invoice_number}.pdf",
      content_type: 'application/pdf'
    )
    
    Rails.logger.info "Receipt PDF uploaded successfully to S3 and Active Storage"
    
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 upload error for receipt: #{e.message}"
    raise "S3への領収書アップロードに失敗しました: #{e.message}"
  rescue => e
    Rails.logger.error "Receipt PDF generation error: #{e.message}"
    raise "領収書PDF生成に失敗しました: #{e.message}"
  end
end