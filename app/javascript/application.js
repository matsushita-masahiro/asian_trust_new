import "rails-ujs"
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"

import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

import "slider"
import "fadein"
import "flash"
import "admin_inquiries"
import "users_show"
import "incentive"
import "order"

// 機能別モジュールをインポート
import CustomDropdown from "custom_dropdown"
import PostalCodeManager from "postal_code_manager"

// グローバルインスタンス
let customDropdown = null;
let postalCodeManager = null;

// PostalCodeManagerをグローバルに公開
window.postalCodeManager = null;

// 初期化関数
function initializeComponents() {
  try {
    // カスタムドロップダウンを初期化
    if (!customDropdown) {
      customDropdown = new CustomDropdown();
    }
    customDropdown.init();

    // 郵便番号自動入力機能を初期化
    if (!postalCodeManager) {
      postalCodeManager = new PostalCodeManager();
      window.postalCodeManager = postalCodeManager; // グローバルに公開
    }
    postalCodeManager.init();
    postalCodeManager.setupAddressEditListeners();

    // Bootstrap コンポーネントの初期化
    initBootstrapComponents();

    console.log("✅ All components initialized");
  } catch (error) {
    console.error("❌ Component initialization error:", error);
  }
}

// Bootstrap コンポーネントの初期化
function initBootstrapComponents() {
  // ツールチップの初期化
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltipTriggerList.forEach(tooltipTriggerEl => {
    if (!tooltipTriggerEl._tooltip) {
      tooltipTriggerEl._tooltip = new bootstrap.Tooltip(tooltipTriggerEl);
    }
  });

  // ポップオーバーの初期化
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
  popoverTriggerList.forEach(popoverTriggerEl => {
    if (!popoverTriggerEl._popover) {
      popoverTriggerEl._popover = new bootstrap.Popover(popoverTriggerEl);
    }
  });
}

// コンポーネントのクリーンアップ関数
function cleanupComponents() {
  try {
    if (customDropdown) {
      customDropdown.cleanup();
    }

    if (postalCodeManager) {
      postalCodeManager.cleanup();
    }

    console.log("✅ Components cleaned up successfully");
  } catch (error) {
    console.error("❌ Error during cleanup:", error);
  }
}

// デバッグ用関数をグローバルに公開
window.testPostalCodeAutoFill = () => {
  if (postalCodeManager) {
    postalCodeManager.test();
  }
};

// イベントリスナーの設定
document.addEventListener("DOMContentLoaded", () => {
  console.log("✅ JavaScript is loaded");

  // jQuery 確認
  if (typeof $ !== "undefined") {
    $(function () {
      console.log("✅ jQuery is loaded");
    });
  }

  // Rails UJS 確認
  console.log("✅ Rails:", typeof Rails !== "undefined" ? "Loaded" : "Not Loaded");

  // コンポーネントを初期化
  initializeComponents();
});

// Turboでページが変わった時にも再初期化
document.addEventListener("turbo:load", () => {
  console.log("🔄 Turbo:load - Reinitializing components");
  initializeComponents();
});

// Turboでページを離れる前にクリーンアップ
document.addEventListener("turbo:before-cache", () => {
  console.log("🧹 Turbo:before-cache - Cleaning up components");
  cleanupComponents();
});

// ページ離脱時のクリーンアップ
window.addEventListener("beforeunload", () => {
  console.log("🧹 Before unload - Final cleanup");
  cleanupComponents();
});
