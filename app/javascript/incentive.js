// Incentive page JavaScript functionality

document.addEventListener('DOMContentLoaded', function() {
  const targetMonthField = document.getElementById('target_month_field');
  const form = document.getElementById('month-selector-form');
  
  if (targetMonthField && form) {
    targetMonthField.addEventListener('change', function() {
      // 階層表示モードの場合は、現在のURLのパラメータを保持
      const currentUrl = new URL(window.location);
      const isDrillDown = currentUrl.pathname.includes('/drill_down');
      
      if (isDrillDown) {
        // drill_downの場合は現在のURLにtarget_monthパラメータを追加
        currentUrl.searchParams.set('target_month', this.value);
        window.location.href = currentUrl.toString();
      } else {
        // 通常のindexの場合はフォームを送信
        form.submit();
      }
    });
  }
});