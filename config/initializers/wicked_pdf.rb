WickedPdf.config ||= {}

# Heroku環境での複数のパスを試行
possible_paths = [
  '/app/bin/wkhtmltopdf',           # Heroku buildpack (新しいパス)
  '/usr/local/bin/wkhtmltopdf',     # Heroku buildpack (古いパス)
  '/usr/bin/wkhtmltopdf',           # 標準的なLinuxパス
  `which wkhtmltopdf`.strip         # システムのPATHから検索
].compact.reject(&:empty?)

wkhtmltopdf_path = possible_paths.find { |path| File.exist?(path) }

if wkhtmltopdf_path
  WickedPdf.config.merge!(exe_path: wkhtmltopdf_path)
  Rails.logger.info("✅ wkhtmltopdf found at #{wkhtmltopdf_path}")
else
  Rails.logger.warn("⚠️ wkhtmltopdf not found in any of these paths: #{possible_paths}")
  Rails.logger.warn("⚠️ PDF generation will not work. Please install wkhtmltopdf buildpack.")
end
