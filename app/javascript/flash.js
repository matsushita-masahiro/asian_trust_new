function initializeFlashMessages() {
  // Bootstrapが利用可能かチェック
  if (!window.bootstrap || !window.bootstrap.Alert) {
    console.log('Bootstrap not available, using fallback');
    initializeFallbackFlashMessages();
    return;
  }
  
  // Bootstrapのalertコンポーネントを初期化
  const alertElements = document.querySelectorAll('.alert');
  alertElements.forEach(alertElement => {
    if (!alertElement._bootstrap_alert) {
      try {
        alertElement._bootstrap_alert = new window.bootstrap.Alert(alertElement);
      } catch (error) {
        console.log('Bootstrap Alert initialization failed:', error);
      }
    }
  });
  
  // 自動消去機能（オプション）
  const autoHideAlerts = document.querySelectorAll('.alert[data-auto-hide]');
  autoHideAlerts.forEach(alert => {
    const delay = parseInt(alert.dataset.autoHide) || 5000;
    setTimeout(() => {
      if (alert._bootstrap_alert) {
        alert._bootstrap_alert.close();
      }
    }, delay);
  });
}

// フォールバック関数（Bootstrapが利用できない場合）
function initializeFallbackFlashMessages() {
  const closeButtons = document.querySelectorAll('.alert .btn-close');
  closeButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      const alert = this.closest('.alert');
      if (alert) {
        alert.style.transition = 'opacity 0.3s';
        alert.style.opacity = '0';
        setTimeout(() => {
          if (alert.parentNode) {
            alert.parentNode.removeChild(alert);
          }
        }, 300);
      }
    });
  });
}

// 複数のイベントに対応
document.addEventListener("DOMContentLoaded", initializeFlashMessages);
document.addEventListener("turbo:load", initializeFlashMessages);
document.addEventListener("turbo:render", initializeFlashMessages);
