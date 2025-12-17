class ClinicReservationManager {
  constructor() {
    this.clinicId = null;
    this.selectedDates = new Set();
    this.init();
  }
  
  init() {
    this.clinicId = document.querySelector('[name="clinic_reservation[clinic_id]"]')?.value;
    console.log('ClinicReservationManager initialized with clinic_id:', this.clinicId);
    this.bindEvents();
    this.initializeDateFields();
  }
  
  bindEvents() {
    // 日付選択時のイベント
    document.querySelectorAll('[name*="preferred_date"]').forEach(field => {
      field.addEventListener('change', (e) => this.handleDateChange(e));
    });
    
    // 時間選択時のイベント（重複チェック用）
    document.querySelectorAll('[name*="preferred_time"]').forEach(field => {
      field.addEventListener('change', (e) => this.handleTimeChange(e));
    });
  }
  
  initializeDateFields() {
    // 初期化時に既に選択されている日付があれば処理
    document.querySelectorAll('[name*="preferred_date"]').forEach(field => {
      if (field.value) {
        this.handleDateChange({ target: field });
      }
    });
  }
  
  async handleDateChange(event) {
    const dateField = event.target;
    const selectedDate = dateField.value;
    const timeFieldName = dateField.name.replace('date', 'time');
    const timeField = document.querySelector(`[name="${timeFieldName}"]`);
    
    console.log('Date changed:', selectedDate, 'clinic_id:', this.clinicId);
    
    if (!selectedDate || !this.clinicId) {
      console.log('Missing date or clinic_id, skipping API call');
      return;
    }
    
    try {
      const apiUrl = `/available_times?clinic_id=${this.clinicId}&date=${selectedDate}`;
      console.log('Fetching available times from:', apiUrl);
      
      const response = await fetch(apiUrl);
      const availableSlots = await response.json();
      
      console.log('API response:', response.status, availableSlots);
      
      if (response.ok) {
        this.updateTimeOptions(timeField, availableSlots);
        this.updateSelectedDates();
      } else {
        console.error('API Error:', availableSlots);
        this.showError('予約可能時間の取得に失敗しました');
      }
      
    } catch (error) {
      console.error('Failed to fetch available times:', error);
      this.showError('予約可能時間の取得に失敗しました');
    }
  }
  
  updateTimeOptions(timeField, availableSlots) {
    // 既存のオプションをクリア
    timeField.innerHTML = '<option value="">選択してください</option>';
    
    // 利用可能な時間帯のみを追加
    availableSlots.forEach(slot => {
      const option = document.createElement('option');
      option.value = slot;
      option.textContent = slot;
      timeField.appendChild(option);
    });
    
    // 利用可能な時間帯がない場合
    if (availableSlots.length === 0) {
      const option = document.createElement('option');
      option.value = '';
      option.textContent = '予約可能な時間帯がありません';
      option.disabled = true;
      timeField.appendChild(option);
    }
  }
  
  updateSelectedDates() {
    // 重複選択の防止ロジック
    this.selectedDates.clear();
    
    document.querySelectorAll('[name*="preferred_date"]').forEach(field => {
      if (field.value) {
        this.selectedDates.add(field.value);
      }
    });
  }
  
  handleTimeChange(event) {
    const timeField = event.target;
    const selectedTime = timeField.value;
    
    if (!selectedTime) return;
    
    // 対応する日付フィールドを取得
    const dateFieldName = timeField.name.replace('time', 'date');
    const dateField = document.querySelector(`[name="${dateFieldName}"]`);
    const selectedDate = dateField?.value;
    
    if (!selectedDate) return;
    
    // 同じ日時の重複をチェック
    const selectedDateTime = `${selectedDate} ${selectedTime}`;
    const duplicateFound = this.checkForDuplicateDateTime(selectedDateTime, timeField.name);
    
    if (duplicateFound) {
      this.showError('同じ日時を複数の希望で選択することはできません');
      timeField.value = ''; // 選択をクリア
    }
  }
  
  checkForDuplicateDateTime(selectedDateTime, currentFieldName) {
    const allTimeFields = document.querySelectorAll('[name*="preferred_time"]');
    
    for (const field of allTimeFields) {
      // 現在のフィールドはスキップ
      if (field.name === currentFieldName) continue;
      
      const dateFieldName = field.name.replace('time', 'date');
      const dateField = document.querySelector(`[name="${dateFieldName}"]`);
      
      if (dateField?.value && field.value) {
        const existingDateTime = `${dateField.value} ${field.value}`;
        if (existingDateTime === selectedDateTime) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  showError(message) {
    // エラーメッセージの表示
    const alertDiv = document.createElement('div');
    alertDiv.className = 'alert alert-warning alert-dismissible fade show';
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    const form = document.querySelector('form');
    form.insertBefore(alertDiv, form.firstChild);
    
    // 5秒後に自動で消去
    setTimeout(() => {
      if (alertDiv.parentNode) {
        alertDiv.remove();
      }
    }, 5000);
  }
}

// Turbo対応の初期化
function initializeClinicReservationManager() {
  // 既存のインスタンスがあれば削除
  if (window.clinicReservationManager) {
    window.clinicReservationManager = null;
  }
  
  // 予約フォームが存在する場合のみ初期化
  if (document.querySelector('[name="clinic_reservation[clinic_id]"]')) {
    window.clinicReservationManager = new ClinicReservationManager();
  }
}

// 複数のイベントに対応
document.addEventListener('DOMContentLoaded', initializeClinicReservationManager);
document.addEventListener('turbo:load', initializeClinicReservationManager);
document.addEventListener('turbo:frame-load', initializeClinicReservationManager);
document.addEventListener('turbo:render', initializeClinicReservationManager);