class CustomDeviseMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'users/mailer'
  default from: ENV['ADMIN_EMAIL'] || 'noreply@example.com'

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @company = InvoiceRecipient.first if defined?(InvoiceRecipient)
    
    mail(to: record.email, subject: 'パスワード再設定のご案内')
  end

  def unlock_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @company = InvoiceRecipient.first if defined?(InvoiceRecipient)
    
    mail(to: record.email, subject: 'アカウントロック解除のご案内')
  end

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @company = InvoiceRecipient.first if defined?(InvoiceRecipient)
    
    mail(to: record.email, subject: 'アカウント確認のご案内')
  end
end