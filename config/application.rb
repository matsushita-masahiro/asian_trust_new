require_relative "boot"
require "rails/all"

# ✅ middleware 読み込み
require_relative "../lib/middleware/force_html_middleware"
require_relative "../lib/middleware/remove_allow_browser_middleware"

Bundler.require(*Rails.groups)

module AsianTrust
  class Application < Rails::Application
    config.load_defaults 8.0

    # ✅ ミドルウェアを先頭に挿入（順序重要）
    config.middleware.insert_before 0, Middleware::RemoveAllowBrowserMiddleware
    config.middleware.insert_before 0, Middleware::ForceHtmlMiddleware

    # ✅ lib 以下を読み込む設定（autoload ではなく eager_load_paths でより確実に）
    config.eager_load_paths << Rails.root.join("lib")
    
    config.time_zone = 'Asia/Tokyo'
    config.active_record.default_timezone = :utc
    
    # Active Storage configuration
    config.active_storage.variant_processor = :mini_magick



    # lib/assets や lib/tasks などのautoload無効化は任意
    config.autoload_lib(ignore: %w[assets tasks])

    # 他の設定は必要に応じて
    # config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
  end
end
