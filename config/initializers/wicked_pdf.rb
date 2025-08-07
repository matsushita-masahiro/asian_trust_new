WickedPdf.config ||= {}

wkhtmltopdf_path =
  if Rails.env.production?
    '/app/bin/wkhtmltopdf' # Heroku buildpack により配置されるパス
  else
    `which wkhtmltopdf`.strip # ローカルの wkhtmltopdf-binary などに対応
  end

# パスが見つかっているか確認してから設定
if File.exist?(wkhtmltopdf_path)
  WickedPdf.config.merge!(exe_path: wkhtmltopdf_path)
else
  Rails.logger.warn("⚠️ wkhtmltopdf not found at #{wkhtmltopdf_path}")
end
