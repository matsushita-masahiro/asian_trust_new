// Users Show Page JavaScript

function toggleEmailEdit() {
  const displayDiv = document.getElementById('email-display');
  const editDiv = document.getElementById('email-edit');

  if (displayDiv.style.display === 'none') {
    displayDiv.style.display = 'block';
    editDiv.style.display = 'none';
  } else {
    displayDiv.style.display = 'none';
    editDiv.style.display = 'block';
    // フォーカスをメールアドレス入力欄に設定
    editDiv.querySelector('input[type="email"]').focus();
  }
}

// グローバルスコープに関数を追加
window.toggleEmailEdit = toggleEmailEdit;

// ページ読み込み時に初期状態を設定
document.addEventListener('DOMContentLoaded', function () {
  const editDiv = document.getElementById('email-edit');
  const displayDiv = document.getElementById('email-display');

  if (editDiv && displayDiv) {
    // 編集フォームを非表示、表示部分を表示
    editDiv.style.display = 'none';
    displayDiv.style.display = 'block';
  }
});

// Turboイベントにも対応（Rails 7のTurbo対応）
document.addEventListener('turbo:load', function () {
  const editDiv = document.getElementById('email-edit');
  const displayDiv = document.getElementById('email-display');

  if (editDiv && displayDiv) {
    // 編集フォームを非表示、表示部分を表示
    editDiv.style.display = 'none';
    displayDiv.style.display = 'block';
  }
});