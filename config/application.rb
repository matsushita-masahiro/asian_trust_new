require_relative "boot"
require "rails/all"

# ✅ lib/middleware のミドルウェアを明示的に読み込む
require_relative "../lib/middleware/force_html_middleware"
require_relative "../lib/middleware/remove_allow_browser_middleware"

Bundler.require(*Rails.groups)

module MasaHp
  class Application < Rails::Application
    # ✅ Rails 8 の初期設定
    config.load_defaults 8.0

    # ✅ lib 以下を eager_load に追加（本番での自動読み込みのため）
    config.eager_load_paths << Rails.root.join("lib")

    # ✅ ミドルウェア登録（← モジュール付きで正確に記述）
    config.middleware.insert_before 0, Middleware::RemoveAllowBrowserMiddleware
    config.middleware.insert_before 0, Middleware::ForceHtmlMiddleware

    # ✅ 不要な lib 配下を除外（任意設定）
    config.autoload_lib(ignore: %w[assets tasks])

    # ✅ タイムゾーンやロケール（必要に応じて調整）
    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
  end
end
