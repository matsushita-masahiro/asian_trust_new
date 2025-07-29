# frozen_string_literal: true

WickedPdf.config ||= {}

WickedPdf.config.merge!(
  exe_path: if Rails.env.production?
              # Heroku 用：wkhtmltopdf-heroku ビルドパス
              '/app/bin/wkhtmltopdf'
            else
              # 開発環境：which でパス取得
              `which wkhtmltopdf`.strip
            end
)
