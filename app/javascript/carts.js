// カートページのJavaScript機能

// 配送先タイプを更新する関数
function updateDeliveryType(radio, itemId) {
  const deliveryType = radio.value;
  const clinicSelection = document.getElementById('clinic-selection-' + itemId);
  const addressSelection = document.getElementById('address-selection-' + itemId);
  const otherDelivery = document.getElementById('other-delivery-' + itemId);
  
  // 全ての配送先選択を非表示
  if (clinicSelection) clinicSelection.style.display = 'none';
  if (addressSelection) addressSelection.style.display = 'none';
  if (otherDelivery) otherDelivery.style.display = 'none';
  
  // 選択されたタイプに応じて表示
  if (deliveryType === 'clinic') {
    if (clinicSelection) clinicSelection.style.display = 'block';
    // クリニック選択の場合は即座にフォーム送信
    radio.form.submit();
  } else if (deliveryType === 'home') {
    if (addressSelection) addressSelection.style.display = 'block';
    // 住所選択の場合は即座にフォーム送信
    radio.form.submit();
  } else if (deliveryType === 'other') {
    if (otherDelivery) {
      otherDelivery.style.display = 'block';
      // その他の場合は入力フィールドの必須属性を設定
      const inputs = otherDelivery.querySelectorAll('input, textarea');
      inputs.forEach(input => {
        input.setAttribute('required', 'required');
      });
    }
  }
}

// 郵便番号フィールドにイベントリスナーを設定する関数
function setupPostalCodeListener(postalCodeInput) {
  postalCodeInput.addEventListener('input', function(e) {
    // 数字以外を削除
    e.target.value = e.target.value.replace(/[^\d]/g, '');
    
    // 7桁入力されたら住所を自動検索
    if (e.target.value.length === 7) {
      // 同じフォーム内の住所フィールドを探す
      const form = e.target.closest('form');
      const addressField = form.querySelector('textarea[name*="other_address"]');
      if (addressField && !addressField.readOnly) {
        searchAddressByPostalCode(e.target.value, addressField);
      }
    }
  });
}

// その他配送の編集を有効化する関数
function enableOtherDeliveryEdit(itemId) {
  const otherDeliveryForm = document.getElementById('other-delivery-' + itemId);
  const inputs = otherDeliveryForm.querySelectorAll('.other-delivery-input');
  const confirmBtn = otherDeliveryForm.querySelector('.btn-success');
  const editBtn = otherDeliveryForm.querySelector('.btn-outline-secondary');
  
  // 入力フィールドを編集可能にする
  inputs.forEach(input => {
    input.removeAttribute('readonly');
    input.classList.remove('form-control-plaintext');
    input.classList.add('form-control');
  });
  
  // 郵便番号フィールドに再度イベントリスナーを設定
  const postalCodeInput = otherDeliveryForm.querySelector('input[name*="other_postal_code"]');
  if (postalCodeInput) {
    // 既存のイベントリスナーをクリア（重複を避けるため）
    const newPostalCodeInput = postalCodeInput.cloneNode(true);
    postalCodeInput.parentNode.replaceChild(newPostalCodeInput, postalCodeInput);
    // 新しいイベントリスナーを設定
    setupPostalCodeListener(newPostalCodeInput);
  }
  
  // ボタンを非表示にする
  if (confirmBtn) confirmBtn.style.display = 'none';
  if (editBtn) editBtn.style.display = 'none';
  
  // 確定ボタンを作成して追加
  const buttonContainer = otherDeliveryForm.querySelector('div:last-child');
  const newConfirmBtn = document.createElement('button');
  newConfirmBtn.type = 'submit';
  newConfirmBtn.className = 'btn btn-primary btn-sm w-100';
  newConfirmBtn.innerHTML = '<i class="fas fa-check me-1"></i>確定';
  
  // 既存のボタンを非表示にして新しいボタンを追加
  buttonContainer.appendChild(newConfirmBtn);
}

// 郵便番号から住所を自動入力する関数
function searchAddressByPostalCode(postalCode, addressField) {
  if (postalCode.length === 7) {
    // zipcloud APIを使用して住所を取得
    fetch(`https://zipcloud.ibsnet.co.jp/api/search?zipcode=${postalCode}`)
      .then(response => response.json())
      .then(data => {
        if (data.status === 200 && data.results && data.results.length > 0) {
          const result = data.results[0];
          const fullAddress = result.address1 + result.address2 + result.address3;
          addressField.value = fullAddress;
        } else {
          console.log('住所が見つかりませんでした');
        }
      })
      .catch(error => {
        console.error('住所検索エラー:', error);
      });
  }
}

// DOMContentLoadedイベントでの初期化
document.addEventListener('DOMContentLoaded', function() {
  // 郵便番号の数字のみ入力制限と住所自動入力
  document.querySelectorAll('input[name*="other_postal_code"]').forEach(function(input) {
    setupPostalCodeListener(input);
  });
  
  // 確定済みの入力フィールドのスタイル調整
  document.querySelectorAll('.other-delivery-input[readonly]').forEach(function(input) {
    input.classList.remove('form-control');
    input.classList.add('form-control-plaintext');
  });
});

// グローバル関数として公開（HTMLから呼び出せるように）
window.updateDeliveryType = updateDeliveryType;
window.enableOtherDeliveryEdit = enableOtherDeliveryEdit;