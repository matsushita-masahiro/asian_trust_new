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

      callbacks = controller._process_action_callbacks

      callbacks_to_remove = callbacks.select do |callback|
        callback.filter.is_a?(Proc) &&
          callback.filter.source_location&.first&.include?(target_path)
      end

      callbacks_to_remove.each do |callback|
        # Railsの内部では skip_callback が例外を出すことがあるので、rescue安全化
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
