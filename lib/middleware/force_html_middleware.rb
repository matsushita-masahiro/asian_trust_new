
# lib/middleware/force_html_middleware.rb

module Middleware
  class ForceHtmlMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      env["HTTP_ACCEPT"] = "text/html" if env["HTTP_ACCEPT"].to_s !~ /html/
      @app.call(env)
    end
  end
end

