class ApplicationMailer < ActionMailer::Base
  default from: ENV['ADMIN_EMAIL'] || "from@example.com"
  layout "mailer"
end
