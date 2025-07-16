# config/initializers/remove_allow_browser.rb

Rails.application.config.to_prepare do
  target_file = 'action_controller/metal/allow_browser.rb'

  ObjectSpace.each_object(Class).select { |klass| klass < ActionController::Base }.each do |controller|
    next unless controller.respond_to?(:_process_action_callbacks)

    old_callbacks = controller._process_action_callbacks

    filtered_callbacks = old_callbacks.reject do |cb|
      cb.filter.is_a?(Proc) &&
      cb.filter.source_location&.first&.include?(target_file)
    end

    controller.reset_callbacks(:process_action)

    filtered_callbacks.each do |cb|
      begin
        controller.set_callback(:process_action, cb.kind, cb.filter, **cb.options)
      rescue => e
        Rails.logger.debug "⚠️ set_callback failed in #{controller.name}: #{e.class} #{e.message}"
      end
    end

    Rails.logger.debug "✅ Reset callbacks for #{controller.name}"
  end
end
