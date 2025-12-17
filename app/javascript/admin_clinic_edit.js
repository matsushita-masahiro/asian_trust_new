// 30分刻みの時間オプションを生成する関数（07:00-23:00）
function generateTimeOptions() {
  let options = '';
  for (let hour = 7; hour <= 23; hour++) {
    for (let minute of [0, 30]) {
      const timeStr = String(hour).padStart(2, '0') + ':' + String(minute).padStart(2, '0');
      options += `<option value="${timeStr}">${timeStr}</option>`;
    }
  }
  return options;
}

document.addEventListener('DOMContentLoaded', function() {
  let breakTimeIndex = parseInt(document.querySelector('[data-break-time-index]')?.dataset.breakTimeIndex || '0');
  let holidayIndex = parseInt(document.querySelector('[data-holiday-index]')?.dataset.holidayIndex || '0');
  
  // 休憩時間追加
  const addBreakTimeBtn = document.getElementById('add-break-time');
  if (addBreakTimeBtn) {
    addBreakTimeBtn.addEventListener('click', function() {
      const container = document.getElementById('break-times-container');
      const newRow = document.createElement('div');
      newRow.className = 'break-time-row row mb-3';
      newRow.innerHTML = `
        <div class="col-md-3">
          <label class="form-label">曜日</label>
          <select name="clinic[clinic_break_times_attributes][${breakTimeIndex}][weekday]" class="form-select">
            <option value="">選択してください</option>
            <option value="0">日曜日</option>
            <option value="1">月曜日</option>
            <option value="2">火曜日</option>
            <option value="3">水曜日</option>
            <option value="4">木曜日</option>
            <option value="5">金曜日</option>
            <option value="6">土曜日</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">開始時間</label>
          <select name="clinic[clinic_break_times_attributes][${breakTimeIndex}][start_time]" class="form-select">
            <option value="">選択してください</option>
            ${generateTimeOptions()}
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">終了時間</label>
          <select name="clinic[clinic_break_times_attributes][${breakTimeIndex}][end_time]" class="form-select">
            <option value="">選択してください</option>
            ${generateTimeOptions()}
          </select>
        </div>
        <div class="col-md-3 d-flex align-items-end">
          <button type="button" class="btn btn-outline-danger btn-sm remove-break-time">削除</button>
        </div>
      `;
      container.appendChild(newRow);
      breakTimeIndex++;
    });
  }
  
  // 休日追加
  const addHolidayBtn = document.getElementById('add-holiday');
  if (addHolidayBtn) {
    addHolidayBtn.addEventListener('click', function() {
      const container = document.getElementById('holidays-container');
      const newRow = document.createElement('div');
      newRow.className = 'holiday-row row mb-3';
      newRow.innerHTML = `
        <div class="col-md-2">
          <label class="form-label">種類</label>
          <select class="form-select holiday-type" data-holiday-type>
            <option value="weekday">定期休日</option>
            <option value="date">特定日</option>
          </select>
        </div>
        <div class="col-md-3 weekday-field">
          <label class="form-label">曜日</label>
          <select name="clinic[clinic_holidays_attributes][${holidayIndex}][weekday]" class="form-select">
            <option value="">選択してください</option>
            <option value="0">日曜日</option>
            <option value="1">月曜日</option>
            <option value="2">火曜日</option>
            <option value="3">水曜日</option>
            <option value="4">木曜日</option>
            <option value="5">金曜日</option>
            <option value="6">土曜日</option>
          </select>
        </div>
        <div class="col-md-3 date-field" style="display: none;">
          <label class="form-label">日付</label>
          <input type="date" name="clinic[clinic_holidays_attributes][${holidayIndex}][date]" class="form-control">
        </div>
        <div class="col-md-3">
          <label class="form-label">理由</label>
          <input type="text" name="clinic[clinic_holidays_attributes][${holidayIndex}][reason]" class="form-control" placeholder="例: 定休日、臨時休診">
        </div>
        <div class="col-md-1 d-flex align-items-end">
          <button type="button" class="btn btn-outline-danger btn-sm remove-holiday">削除</button>
        </div>
      `;
      container.appendChild(newRow);
      holidayIndex++;
    });
  }
  
  // 削除ボタンのイベント委譲（特定のコンテナ内のみ）
  const breakTimesContainer = document.getElementById('break-times-container');
  const holidaysContainer = document.getElementById('holidays-container');
  
  if (breakTimesContainer) {
    breakTimesContainer.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-break-time')) {
        e.preventDefault();
        e.stopPropagation();
        
        const row = e.target.closest('.break-time-row');
        const destroyField = row.querySelector('.destroy-field');
        
        if (destroyField) {
          // 既存のレコードの場合は_destroyフィールドをtrueに設定して非表示
          destroyField.value = 'true';
          row.style.display = 'none';
        } else {
          // 新規追加されたレコードの場合は完全に削除
          row.remove();
        }
      }
    });
  }
  
  if (holidaysContainer) {
    holidaysContainer.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-holiday')) {
        e.preventDefault();
        e.stopPropagation();
        
        const row = e.target.closest('.holiday-row');
        const destroyField = row.querySelector('.destroy-field');
        
        if (destroyField) {
          // 既存のレコードの場合は_destroyフィールドをtrueに設定して非表示
          destroyField.value = 'true';
          row.style.display = 'none';
        } else {
          // 新規追加されたレコードの場合は完全に削除
          row.remove();
        }
      }
    });
  }
  
  // 休日種類変更時の表示切り替え（特定のコンテナ内のみ）
  if (holidaysContainer) {
    holidaysContainer.addEventListener('change', function(e) {
      if (e.target.classList.contains('holiday-type')) {
        const row = e.target.closest('.holiday-row');
        const weekdayField = row.querySelector('.weekday-field');
        const dateField = row.querySelector('.date-field');
        
        if (e.target.value === 'weekday') {
          weekdayField.style.display = 'block';
          dateField.style.display = 'none';
          dateField.querySelector('input').value = '';
        } else {
          weekdayField.style.display = 'none';
          dateField.style.display = 'block';
          weekdayField.querySelector('select').value = '';
        }
      }
    });
  }
  
  // Flash メッセージの初期化（このページ専用）
  initializeFlashForThisPage();
});

// Flash メッセージの初期化関数
function initializeFlashForThisPage() {
  console.log('Initializing flash messages for clinic edit page');
  console.log('Bootstrap available:', !!window.bootstrap);
  console.log('Bootstrap Alert available:', !!(window.bootstrap && window.bootstrap.Alert));
  
  // 既存のイベントリスナーをクリア
  const existingButtons = document.querySelectorAll('.alert .btn-close');
  console.log('Found close buttons:', existingButtons.length);
  
  existingButtons.forEach(button => {
    const newButton = button.cloneNode(true);
    button.parentNode.replaceChild(newButton, button);
  });
  
  // 新しいイベントリスナーを追加
  const closeButtons = document.querySelectorAll('.alert .btn-close');
  closeButtons.forEach(button => {
    console.log('Adding click listener to close button');
    
    button.addEventListener('click', function(e) {
      console.log('Close button clicked');
      e.preventDefault();
      e.stopPropagation();
      
      const alert = this.closest('.alert');
      if (alert) {
        console.log('Closing alert');
        alert.style.transition = 'opacity 0.3s';
        alert.style.opacity = '0';
        setTimeout(() => {
          if (alert.parentNode) {
            alert.parentNode.removeChild(alert);
            console.log('Alert removed');
          }
        }, 300);
      }
    });
  });
  
  // Bootstrap Alertも試す
  const alertElements = document.querySelectorAll('.alert');
  alertElements.forEach(alertElement => {
    if (window.bootstrap && window.bootstrap.Alert) {
      try {
        new window.bootstrap.Alert(alertElement);
        console.log('Bootstrap Alert initialized');
      } catch (error) {
        console.log('Bootstrap Alert initialization failed:', error);
      }
    } else {
      console.log('Bootstrap not available, using manual implementation');
    }
  });
}