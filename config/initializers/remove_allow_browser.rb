Rails.application.config.after_initialize do
  target_file = 'action_controller/metal/allow_browser.rb'

  ObjectSpace.each_object(Class).select { |klass|
    klass < ActionController::Base
  }.each do |controller|
    next unless controller.respond_to?(:_process_action_callbacks)

    removed = false

    controller._process_action_callbacks.each do |callback|
      next unless callback.filter.is_a?(Proc)
      next unless callback.filter.source_location&.first&.include?(target_file)

      begin
        controller.skip_callback(
          :process_action,
          callback.kind,
          callback.filter
        )
        removed = true
      rescue => e
        Rails.logger.debug("⚠️ skip_callback failed in #{controller.name}: #{e.class} #{e.message}")
      end
    end

    puts "🧹 Removed AllowBrowser from #{controller.name}" if removed
  end
end
