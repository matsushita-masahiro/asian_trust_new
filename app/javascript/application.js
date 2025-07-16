import "rails-ujs"  // Rails.start() はこの中で一度だけ呼ばれる
// importmap で pin "rails-ujs", to: "rails-ujs.js" と定義している

import "@hotwired/turbo-rails"
import "controllers"
import "jquery"

import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

import "slider"
import "fadein"
import "flash"
import "admin_inquiries"

document.addEventListener("DOMContentLoaded", () => {
  // ✅ jQuery 確認
  if (typeof $ !== "undefined") {
    $(function () {
      console.log("✅ jQuery is loaded");
    });
  }

  console.log("✅ JavaScript is loaded");

  // ✅ Rails UJS 確認だけ（startしない）
  console.log("✅ Rails:", typeof Rails !== "undefined" ? "Loaded" : "Not Loaded");
});
