# lib/middleware/force_html_middleware.rb
module Middleware
  class ForceHtmlMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['HTTP_ACCEPT']&.include?('text/vnd.turbo-stream.html')
        env['HTTP_ACCEPT'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      end
      @app.call(env)
    end
  end
end
