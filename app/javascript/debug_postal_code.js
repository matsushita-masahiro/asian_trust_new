// 郵便番号自動入力機能のデバッグ用スクリプト
// ブラウザのコンソールで実行して問題を診断

function debugPostalCodeAutoFill() {
  console.log("=== 郵便番号自動入力機能 デバッグ開始 ===");
  
  // 1. DOM要素の確認
  console.log("1. DOM要素の確認:");
  const postalCodeFields = document.querySelectorAll('input[name*="postal_code"], .postal-code-input');
  const addressFields = document.querySelectorAll('textarea[name*="address"], .address-input');
  
  console.log(`郵便番号フィールド数: ${postalCodeFields.length}`);
  postalCodeFields.forEach((field, index) => {
    console.log(`  ${index + 1}. ID: ${field.id}, Name: ${field.name}, Class: ${field.className}`);
  });
  
  console.log(`住所フィールド数: ${addressFields.length}`);
  addressFields.forEach((field, index) => {
    console.log(`  ${index + 1}. ID: ${field.id}, Name: ${field.name}, Class: ${field.className}`);
  });
  
  // 2. PostalCodeAutoFillクラスの確認
  console.log("2. PostalCodeAutoFillクラスの確認:");
  console.log("PostalCodeAutoFill:", typeof PostalCodeAutoFill !== 'undefined' ? "✅ 読み込み済み" : "❌ 未読み込み");
  
  // 3. インスタンスの確認
  console.log("3. インスタンスの確認:");
  if (window.postalCodeAutoFillInstances) {
    console.log(`アクティブなインスタンス数: ${window.postalCodeAutoFillInstances.length}`);
    window.postalCodeAutoFillInstances.forEach((instance, index) => {
      console.log(`  インスタンス ${index + 1}:`, instance);
    });
  } else {
    console.log("インスタンス配列が存在しません");
  }
  
  // 4. イベントリスナーのテスト
  console.log("4. イベントリスナーのテスト:");
  postalCodeFields.forEach((field, index) => {
    console.log(`フィールド ${index + 1} のイベントリスナー数:`, getEventListeners ? getEventListeners(field) : "getEventListeners未対応");
  });
  
  // 5. 手動テスト用の関数を提供
  window.testPostalCode = function(postalCode = "1000001") {
    console.log(`テスト用郵便番号 ${postalCode} を入力...`);
    const firstPostalField = postalCodeFields[0];
    if (firstPostalField) {
      firstPostalField.value = postalCode;
      firstPostalField.dispatchEvent(new Event('input', { bubbles: true }));
      console.log("入力イベントを発火しました");
    } else {
      console.log("郵便番号フィールドが見つかりません");
    }
  };
  
  console.log("=== デバッグ完了 ===");
  console.log("手動テスト: testPostalCode('1000001') を実行してください");
}

// ページ読み込み後に自動実行
document.addEventListener('DOMContentLoaded', function() {
  setTimeout(debugPostalCodeAutoFill, 1000);
});

export default debugPostalCodeAutoFill;