class ReceiptPdfService
  include ApplicationHelper
  require 'digest'
  
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
        invoice: @invoice
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
end