class ApplicationMailer < ActionMailer::Base
  default from: ENV['ADMIN_EMAIL'] || "from@example.com"
  layout "mailer"

  add_template_helper(ApplicationHelper)
end
