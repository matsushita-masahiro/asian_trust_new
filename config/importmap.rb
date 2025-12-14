# Pin npm packages by running ./bin/importmap

pin "application"
pin "rails-ujs", to: "rails-ujs.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "jquery", to: "https://code.jquery.com/jquery-3.6.0.min.js"

pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.esm.min.js"
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/esm/index.js"

pin "slider", to: "slider.js"
pin "fadein", to: "fadein.js"
pin "flash", to: "flash.js" 
pin "admin_inquiries", to: "admin_inquiries.js"
pin "users_show", to: "users_show.js"
pin "incentive", to: "incentive.js"
pin "order", to: "order.js"
pin "carts", to: "carts.js"
pin "postal_code_auto_fill", to: "postal_code_auto_fill.js"
pin "custom_dropdown", to: "custom_dropdown.js"
pin "postal_code_manager", to: "postal_code_manager.js"


