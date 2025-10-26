import "rails-ujs"  // Rails.start() はこの中で一度だけ呼ばれる
// importmap で pin "rails-ujs", to: "rails-ujs.js" と定義している

import "@hotwired/turbo-rails"
import "controllers"
import "jquery"

import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

// カスタムドロップダウン初期化
function initCustomDropdown() {
  const dropdownToggle = document.getElementById('mypageDropdown');
  const dropdownMenu = document.getElementById('mypageDropdownMenu');
  
  if (!dropdownToggle || !dropdownMenu) {
    console.log("Dropdown elements not found");
    return;
  }

  // 既存のイベントリスナーを削除
  dropdownToggle.removeEventListener('click', handleDropdownToggle);
  document.removeEventListener('click', handleDocumentClick);

  // ドロップダウントグルクリック
  function handleDropdownToggle(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const isOpen = dropdownMenu.classList.contains('show');
    
    if (isOpen) {
      dropdownMenu.classList.remove('show');
    } else {
      dropdownMenu.classList.add('show');
    }
  }

  // ドキュメントクリック（外部クリックで閉じる）
  function handleDocumentClick(e) {
    if (!dropdownToggle.contains(e.target) && !dropdownMenu.contains(e.target)) {
      dropdownMenu.classList.remove('show');
    }
  }

  // イベントリスナーを追加
  dropdownToggle.addEventListener('click', handleDropdownToggle);
  document.addEventListener('click', handleDocumentClick);

  // ESCキーで閉じる
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      dropdownMenu.classList.remove('show');
    }
  });

  console.log("✅ Custom dropdown initialized");
}

import "slider"
import "fadein"
import "flash"
import "admin_inquiries"
import "users_show"
import "incentive"
import "order"

// 初期化関数
function initializeComponents() {
  // カスタムドロップダウンを初期化
  initCustomDropdown();

  // ツールチップの初期化（必要に応じて）
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltipTriggerList.forEach(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

  // ポップオーバーの初期化（必要に応じて）
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
  popoverTriggerList.forEach(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));

  console.log("✅ All components initialized");
}



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

  // コンポーネントを初期化
  initializeComponents();
});

// Turboでページが変わった時にも再初期化
document.addEventListener("turbo:load", () => {
  console.log("🔄 Turbo:load - Reinitializing components");
  initializeComponents();
});
