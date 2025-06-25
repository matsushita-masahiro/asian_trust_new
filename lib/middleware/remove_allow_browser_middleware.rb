# lib/middleware/remove_allow_browser_middleware.rb

module Middleware
  class RemoveAllowBrowserMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      disable_allow_browser
      @app.call(env)
    end

    private

    def disable_allow_browser
      target_path = 'action_controller/metal/allow_browser.rb'

      ObjectSpace.each_object(Class).select { |klass|
        klass < ActionController::Base
      }.each do |controller|
        next unless controller.respond_to?(:_process_action_callbacks)

        controller._process_action_callbacks.each do |callback|
          next unless callback.filter.is_a?(Proc)
          next unless callback.filter.source_location&.first&.include?(target_path)

          begin
            controller.skip_callback(
              :process_action,
              callback.kind,
              callback.filter
            )
          rescue => e
            Rails.logger.debug("⚠️ AllowBrowser callback skip failed: #{e.class} #{e.message}")
          end
        end
      end
    end
  end
end
