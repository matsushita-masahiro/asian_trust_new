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
      allow_browser_path = "action_controller/metal/allow_browser.rb"

      ObjectSpace.each_object(Class).select { |klass| klass < ActionController::Base }.each do |controller|
        next unless controller.respond_to?(:_process_action_callbacks)

        controller._process_action_callbacks.each do |callback|
          next unless callback.filter.is_a?(Proc)

          if callback.filter.source_location&.first&.include?(allow_browser_path)
            begin
              controller.skip_callback(
                :process_action,
                callback.kind,
                callback.filter
              )
              Rails.logger.debug("✅ Removed AllowBrowser filter from #{controller.name}")
            rescue => e
              Rails.logger.warn("⚠️ Failed to remove AllowBrowser from #{controller.name}: #{e.class} #{e.message}")
            end
          end
        end
      end
    end
  end
end
