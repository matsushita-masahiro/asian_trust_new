Rails.application.config.after_initialize do
  target_file = 'action_controller/metal/allow_browser.rb'

  ObjectSpace.each_object(Class).select { |klass|
    klass < ActionController::Base
  }.each do |controller|
    next unless controller.respond_to?(:_process_action_callbacks)

    removed = controller._process_action_callbacks.delete_if do |callback|
      callback.filter.is_a?(Proc) &&
        callback.filter.source_location&.first&.include?(target_file)
    end

    puts "🧹 Removed AllowBrowser from #{controller.name}" if removed.any?
  end
end
