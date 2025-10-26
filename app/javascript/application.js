import "rails-ujs"  // Rails.start() はこの中で一度だけ呼ばれる
// importmap で pin "rails-ujs", to: "rails-ujs.js" と定義している

import "@hotwired/turbo-rails"
import "controllers"
import "jquery"

import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

// カスタムドロップダウンアニメーション関数
function initCustomDropdowns() {
  const dropdownToggles = document.querySelectorAll('.dropdown-toggle');

  dropdownToggles.forEach(toggle => {
    const dropdownMenu = toggle.nextElementSibling;
    let isOpen = false;

    // 既存のイベントリスナーを削除
    toggle.removeEventListener('click', handleDropdownClick);

    // クリックイベント
    function handleDropdownClick(e) {
      e.preventDefault();
      e.stopPropagation();

      // 他のドロップダウンを閉じる
      closeAllDropdowns();

      if (!isOpen) {
        openDropdown(dropdownMenu);
        isOpen = true;
      } else {
        closeDropdown(dropdownMenu);
        isOpen = false;
      }
    }

    toggle.addEventListener('click', handleDropdownClick);

    // ドロップダウンメニュー外をクリックした時に閉じる
    document.addEventListener('click', (e) => {
      if (!toggle.contains(e.target) && !dropdownMenu.contains(e.target)) {
        if (isOpen) {
          closeDropdown(dropdownMenu);
          isOpen = false;
        }
      }
    });

    // ESCキーで閉じる
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && isOpen) {
        closeDropdown(dropdownMenu);
        isOpen = false;
      }
    });
  });
}

// ドロップダウンを開く
function openDropdown(menu) {
  menu.classList.add('show');
  // アニメーション用の小さな遅延
  setTimeout(() => {
    menu.style.opacity = '1';
    menu.style.transform = 'translateY(0)';
  }, 10);
}

// ドロップダウンを閉じる
function closeDropdown(menu) {
  menu.style.opacity = '0';
  menu.style.transform = 'translateY(-10px)';

  // アニメーション完了後にshowクラスを削除
  setTimeout(() => {
    menu.classList.remove('show');
  }, 300);
}

// 全てのドロップダウンを閉じる
function closeAllDropdowns() {
  const openDropdowns = document.querySelectorAll('.dropdown-menu.show');
  openDropdowns.forEach(menu => {
    closeDropdown(menu);
  });
}

import "slider"
import "fadein"
import "flash"
import "admin_inquiries"
import "users_show"
import "incentive"
import "order"

// Bootstrapドロップダウンの初期化関数
function initializeBootstrapComponents() {
  // カスタムドロップダウンアニメーションを初期化
  initCustomDropdowns();

  // ツールチップの初期化（必要に応じて）
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltipTriggerList.forEach(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

  // ポップオーバーの初期化（必要に応じて）
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
  popoverTriggerList.forEach(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));

  console.log("✅ Bootstrap components initialized");
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

  // Bootstrapコンポーネントを初期化
  initializeBootstrapComponents();
});

// Turboでページが変わった時にもBootstrapを再初期化
document.addEventListener("turbo:load", () => {
  initializeBootstrapComponents();
});

// Turboでページが描画された後にもBootstrapを再初期化
document.addEventListener("turbo:render", () => {
  initializeBootstrapComponents();
});
