WickedPdf.config ||= {}

if Rails.env.production?
  WickedPdf.config.merge!(
    exe_path: '/app/bin/wkhtmltopdf' # Herokuのデフォルトパス
  )
else
  WickedPdf.config.merge!(
    exe_path: `which wkhtmltopdf`.strip # wkhtmltopdf-binaryにより自動パス指定
  )
end
