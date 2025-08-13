Recaptcha.configure do |config|
  config.site_key = ENV['RECAPTCHA_SITE_KEY']
  config.secret_key = ENV['RECAPTCHA_SECRET_KEY']
  
  # 開発環境ではreCAPTCHAをスキップ（オプション）
  config.skip_verify_env = ['development', 'test'] if Rails.env.development?
end