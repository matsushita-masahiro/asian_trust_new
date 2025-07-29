WickedPdf.config ||= {}

if Rails.env.production?
  WickedPdf.config.merge!(
    exe_path: '/app/bin/wkhtmltopdf' # Herokuのパス
  )
else
  # 開発環境用パス（必要に応じて変更）
  WickedPdf.config.merge!(
    exe_path: `which wkhtmltopdf`.strip
  )
end
