# 郵便番号自動住所入力機能 他のフォームでの利用方法

## 概要

郵便番号自動住所入力機能は、様々なフォームで再利用可能な設計になっています。このドキュメントでは、現在の実装（`app/views/users/show.html.erb`）以外のフォームで機能を利用する方法を詳しく説明します。

## 目次

1. [基本的な実装パターン](#基本的な実装パターン)
2. [Railsフォームでの実装](#railsフォームでの実装)
3. [複数住所フォームでの実装](#複数住所フォームでの実装)
4. [動的フォームでの実装](#動的フォームでの実装)
5. [モーダルフォームでの実装](#モーダルフォームでの実装)
6. [既存フォームへの追加](#既存フォームへの追加)
7. [特殊なケースでの実装](#特殊なケースでの実装)

## 基本的な実装パターン

### 1. 最小限の実装

任意のHTMLフォームに郵便番号自動入力機能を追加する最も簡単な方法：

```html
<!-- HTML -->
<form>
  <div class="form-group">
    <label for="postal_code">郵便番号</label>
    <input type="text" 
           id="postal_code" 
           name="postal_code" 
           class="form-control"
           placeholder="例: 123-4567">
  </div>
  
  <div class="form-group">
    <label for="address">住所</label>
    <textarea id="address" 
              name="address" 
              class="form-control"
              rows="3"
              placeholder="住所が自動入力されます"></textarea>
  </div>
</form>
```

```javascript
// JavaScript
import PostalCodeAutoFill from './postal_code_auto_fill.js';

document.addEventListener('DOMContentLoaded', function() {
  const autoFill = new PostalCodeAutoFill({
    postalCodeSelector: '#postal_code',
    addressSelector: '#address'
  });
  autoFill.init();
});
```

### 2. クラスベースの実装

複数のフォームで使用する場合は、クラスセレクターを使用：

```html
<!-- HTML -->
<form class="address-form">
  <input type="text" 
         name="postal_code" 
         class="form-control postal-code-input"
         placeholder="例: 123-4567">
  
  <textarea name="address" 
            class="form-control address-input"
            rows="3"
            placeholder="住所が自動入力されます"></textarea>
</form>
```

```javascript
// JavaScript
const autoFill = new PostalCodeAutoFill({
  postalCodeSelector: '.postal-code-input',
  addressSelector: '.address-input'
});
autoFill.init();
```

## Railsフォームでの実装

### 1. 新規作成フォーム

#### コントローラー

```ruby
# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  def new
    @company = Company.new
  end
  
  def create
    @company = Company.new(company_params)
    
    if @company.save
      redirect_to @company, notice: '会社情報が正常に登録されました。'
    else
      render :new
    end
  end
  
  private
  
  def company_params
    params.require(:company).permit(:name, :postal_code, :address, :phone)
  end
end
```

#### ビュー

```erb
<!-- app/views/companies/new.html.erb -->
<div class="container">
  <h2>会社情報登録</h2>
  
  <%= form_with model: @company, local: true, class: "company-form" do |f| %>
    <% if @company.errors.any? %>
      <div class="alert alert-danger">
        <h4><%= pluralize(@company.errors.count, "error") %> prohibited this company from being saved:</h4>
        <ul>
          <% @company.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>
    
    <div class="row">
      <div class="col-md-8">
        <%= f.label :name, "会社名", class: "form-label" %>
        <%= f.text_field :name, class: "form-control", required: true %>
      </div>
    </div>
    
    <div class="row mt-3">
      <div class="col-md-4">
        <%= f.label :postal_code, "郵便番号", class: "form-label" %>
        <%= f.text_field :postal_code, 
            class: "form-control postal-code-input",
            placeholder: "例: 123-4567" %>
      </div>
    </div>
    
    <div class="row mt-3">
      <div class="col-12">
        <%= f.label :address, "住所", class: "form-label" %>
        <%= f.text_area :address, 
            class: "form-control address-input",
            rows: 3,
            placeholder: "住所が自動入力されます" %>
      </div>
    </div>
    
    <div class="row mt-3">
      <div class="col-md-6">
        <%= f.label :phone, "電話番号", class: "form-label" %>
        <%= f.text_field :phone, class: "form-control" %>
      </div>
    </div>
    
    <div class="row mt-4">
      <div class="col-12">
        <%= f.submit "登録", class: "btn btn-primary" %>
        <%= link_to "戻る", companies_path, class: "btn btn-secondary" %>
      </div>
    </div>
  <% end %>
</div>
```

#### JavaScript初期化

```javascript
// app/javascript/companies.js
import PostalCodeAutoFill from './postal_code_auto_fill.js';

document.addEventListener('DOMContentLoaded', function() {
  initializeCompanyForm();
});

document.addEventListener('turbo:load', function() {
  initializeCompanyForm();
});

function initializeCompanyForm() {
  // 会社フォームページでのみ初期化
  const companyForm = document.querySelector('.company-form');
  if (companyForm) {
    const autoFill = new PostalCodeAutoFill({
      postalCodeSelector: '.company-form .postal-code-input',
      addressSelector: '.company-form .address-input'
    });
    
    if (autoFill.init()) {
      console.log('会社フォームの郵便番号自動入力機能を初期化しました');
    }
  }
}
```

### 2. 編集フォーム

```erb
<!-- app/views/companies/edit.html.erb -->
<div class="container">
  <h2>会社情報編集</h2>
  
  <%= form_with model: @company, local: true, class: "company-edit-form" do |f| %>
    <!-- 同様のフォーム構造 -->
    
    <div class="row mt-4">
      <div class="col-12">
        <%= f.submit "更新", class: "btn btn-primary" %>
        <%= link_to "詳細", @company, class: "btn btn-info" %>
        <%= link_to "戻る", companies_path, class: "btn btn-secondary" %>
      </div>
    </div>
  <% end %>
</div>
```

```javascript
// 編集フォーム用の初期化
function initializeCompanyEditForm() {
  const editForm = document.querySelector('.company-edit-form');
  if (editForm) {
    const autoFill = new PostalCodeAutoFill({
      postalCodeSelector: '.company-edit-form .postal-code-input',
      addressSelector: '.company-edit-form .address-input'
    });
    autoFill.init();
  }
}
```

## 複数住所フォームでの実装

### 1. 請求先・配送先住所

```erb
<!-- app/views/orders/new.html.erb -->
<%= form_with model: @order, local: true do |f| %>
  <!-- 請求先住所 -->
  <div class="billing-address-section">
    <h4>請求先住所</h4>
    
    <div class="row">
      <div class="col-md-4">
        <%= f.label :billing_postal_code, "郵便番号", class: "form-label" %>
        <%= f.text_field :billing_postal_code, 
            class: "form-control postal-code-input",
            data: { address_type: "billing" },
            placeholder: "例: 123-4567" %>
      </div>
    </div>
    
    <div class="row mt-2">
      <div class="col-12">
        <%= f.label :billing_address, "住所", class: "form-label" %>
        <%= f.text_area :billing_address, 
            class: "form-control address-input",
            data: { address_type: "billing" },
            rows: 2,
            placeholder: "住所が自動入力されます" %>
      </div>
    </div>
  </div>
  
  <!-- 配送先住所 -->
  <div class="shipping-address-section mt-4">
    <h4>配送先住所</h4>
    
    <div class="form-check mb-3">
      <%= f.check_box :same_as_billing, class: "form-check-input", id: "same-as-billing" %>
      <%= f.label :same_as_billing, "請求先住所と同じ", class: "form-check-label", for: "same-as-billing" %>
    </div>
    
    <div id="shipping-address-fields">
      <div class="row">
        <div class="col-md-4">
          <%= f.label :shipping_postal_code, "郵便番号", class: "form-label" %>
          <%= f.text_field :shipping_postal_code, 
              class: "form-control postal-code-input",
              data: { address_type: "shipping" },
              placeholder: "例: 123-4567" %>
        </div>
      </div>
      
      <div class="row mt-2">
        <div class="col-12">
          <%= f.label :shipping_address, "住所", class: "form-label" %>
          <%= f.text_area :shipping_address, 
              class: "form-control address-input",
              data: { address_type: "shipping" },
              rows: 2,
              placeholder: "住所が自動入力されます" %>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

```javascript
// 複数住所フォームの初期化
function initializeMultipleAddressForm() {
  // 請求先住所
  const billingAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: 'input[data-address-type="billing"].postal-code-input',
    addressSelector: 'textarea[data-address-type="billing"].address-input'
  });
  billingAutoFill.init();
  
  // 配送先住所
  const shippingAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: 'input[data-address-type="shipping"].postal-code-input',
    addressSelector: 'textarea[data-address-type="shipping"].address-input'
  });
  shippingAutoFill.init();
  
  // 「請求先住所と同じ」チェックボックスの処理
  const sameAsBillingCheckbox = document.getElementById('same-as-billing');
  const shippingFields = document.getElementById('shipping-address-fields');
  
  if (sameAsBillingCheckbox && shippingFields) {
    sameAsBillingCheckbox.addEventListener('change', function() {
      if (this.checked) {
        shippingFields.style.display = 'none';
        copyBillingToShipping();
      } else {
        shippingFields.style.display = 'block';
      }
    });
  }
}

function copyBillingToShipping() {
  const billingPostalCode = document.querySelector('input[data-address-type="billing"].postal-code-input');
  const billingAddress = document.querySelector('textarea[data-address-type="billing"].address-input');
  const shippingPostalCode = document.querySelector('input[data-address-type="shipping"].postal-code-input');
  const shippingAddress = document.querySelector('textarea[data-address-type="shipping"].address-input');
  
  if (billingPostalCode && shippingPostalCode) {
    shippingPostalCode.value = billingPostalCode.value;
  }
  
  if (billingAddress && shippingAddress) {
    shippingAddress.value = billingAddress.value;
  }
}
```

### 2. 複数の同種住所

```erb
<!-- 複数の営業所住所など -->
<div id="offices-container">
  <h4>営業所住所</h4>
  
  <div class="office-form" data-office-id="1">
    <h5>営業所 1</h5>
    <div class="row">
      <div class="col-md-4">
        <label class="form-label">郵便番号</label>
        <input type="text" 
               name="offices[1][postal_code]" 
               class="form-control postal-code-input"
               data-office-id="1"
               placeholder="例: 123-4567">
      </div>
    </div>
    <div class="row mt-2">
      <div class="col-12">
        <label class="form-label">住所</label>
        <textarea name="offices[1][address]" 
                  class="form-control address-input"
                  data-office-id="1"
                  rows="2"
                  placeholder="住所が自動入力されます"></textarea>
      </div>
    </div>
  </div>
</div>

<button type="button" id="add-office-btn" class="btn btn-secondary">営業所を追加</button>
```

```javascript
// 複数営業所フォームの管理
class MultipleOfficeManager {
  constructor() {
    this.officeCount = 1;
    this.autoFillInstances = [];
    this.initializeExistingOffices();
    this.setupAddButton();
  }
  
  initializeExistingOffices() {
    document.querySelectorAll('.office-form').forEach(form => {
      const officeId = form.dataset.officeId;
      this.initializeOfficeAutoFill(officeId);
    });
  }
  
  initializeOfficeAutoFill(officeId) {
    const autoFill = new PostalCodeAutoFill({
      postalCodeSelector: `input[data-office-id="${officeId}"].postal-code-input`,
      addressSelector: `textarea[data-office-id="${officeId}"].address-input`
    });
    
    if (autoFill.init()) {
      this.autoFillInstances.push({
        officeId: officeId,
        instance: autoFill
      });
    }
  }
  
  setupAddButton() {
    const addButton = document.getElementById('add-office-btn');
    if (addButton) {
      addButton.addEventListener('click', () => this.addOffice());
    }
  }
  
  addOffice() {
    this.officeCount++;
    const officeId = this.officeCount;
    
    const officeHtml = `
      <div class="office-form mt-3" data-office-id="${officeId}">
        <h5>営業所 ${officeId}</h5>
        <div class="row">
          <div class="col-md-4">
            <label class="form-label">郵便番号</label>
            <input type="text" 
                   name="offices[${officeId}][postal_code]" 
                   class="form-control postal-code-input"
                   data-office-id="${officeId}"
                   placeholder="例: 123-4567">
          </div>
        </div>
        <div class="row mt-2">
          <div class="col-12">
            <label class="form-label">住所</label>
            <textarea name="offices[${officeId}][address]" 
                      class="form-control address-input"
                      data-office-id="${officeId}"
                      rows="2"
                      placeholder="住所が自動入力されます"></textarea>
          </div>
        </div>
        <button type="button" class="btn btn-sm btn-danger mt-2" 
                onclick="officeManager.removeOffice(${officeId})">削除</button>
      </div>
    `;
    
    document.getElementById('offices-container').insertAdjacentHTML('beforeend', officeHtml);
    this.initializeOfficeAutoFill(officeId);
  }
  
  removeOffice(officeId) {
    // フォームを削除
    const officeForm = document.querySelector(`[data-office-id="${officeId}"]`);
    if (officeForm) {
      officeForm.remove();
    }
    
    // AutoFillインスタンスを削除
    const index = this.autoFillInstances.findIndex(item => item.officeId == officeId);
    if (index !== -1) {
      this.autoFillInstances[index].instance.destroy();
      this.autoFillInstances.splice(index, 1);
    }
  }
}

// 使用例
let officeManager;
document.addEventListener('DOMContentLoaded', function() {
  officeManager = new MultipleOfficeManager();
});
```

## 動的フォームでの実装

### 1. JavaScript で動的に追加されるフォーム

```javascript
// 動的フォーム管理クラス
class DynamicAddressFormManager {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.formCount = 0;
    this.autoFillInstances = [];
  }
  
  addForm(formData = {}) {
    this.formCount++;
    const formId = `address-form-${this.formCount}`;
    
    const formHtml = this.generateFormHtml(formId, formData);
    this.container.insertAdjacentHTML('beforeend', formHtml);
    
    // 郵便番号自動入力機能を初期化
    this.initializeAutoFill(formId);
    
    return formId;
  }
  
  generateFormHtml(formId, formData) {
    return `
      <div id="${formId}" class="dynamic-address-form border p-3 mb-3">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5>住所 ${this.formCount}</h5>
          <button type="button" class="btn btn-sm btn-danger" 
                  onclick="dynamicFormManager.removeForm('${formId}')">削除</button>
        </div>
        
        <div class="row">
          <div class="col-md-6">
            <label class="form-label">名前</label>
            <input type="text" 
                   name="addresses[${this.formCount}][name]" 
                   class="form-control"
                   value="${formData.name || ''}">
          </div>
          <div class="col-md-4">
            <label class="form-label">郵便番号</label>
            <input type="text" 
                   name="addresses[${this.formCount}][postal_code]" 
                   class="form-control postal-code-input"
                   placeholder="例: 123-4567"
                   value="${formData.postal_code || ''}">
          </div>
        </div>
        
        <div class="row mt-2">
          <div class="col-12">
            <label class="form-label">住所</label>
            <textarea name="addresses[${this.formCount}][address]" 
                      class="form-control address-input"
                      rows="2"
                      placeholder="住所が自動入力されます">${formData.address || ''}</textarea>
          </div>
        </div>
      </div>
    `;
  }
  
  initializeAutoFill(formId) {
    const autoFill = new PostalCodeAutoFill({
      postalCodeSelector: `#${formId} .postal-code-input`,
      addressSelector: `#${formId} .address-input`
    });
    
    if (autoFill.init()) {
      this.autoFillInstances.push({
        formId: formId,
        instance: autoFill
      });
    }
  }
  
  removeForm(formId) {
    // フォームを削除
    const form = document.getElementById(formId);
    if (form) {
      form.remove();
    }
    
    // AutoFillインスタンスを削除
    const index = this.autoFillInstances.findIndex(item => item.formId === formId);
    if (index !== -1) {
      this.autoFillInstances[index].instance.destroy();
      this.autoFillInstances.splice(index, 1);
    }
  }
  
  getAllFormData() {
    const forms = this.container.querySelectorAll('.dynamic-address-form');
    const data = [];
    
    forms.forEach(form => {
      const formData = new FormData(form);
      const addressData = {};
      
      for (let [key, value] of formData.entries()) {
        addressData[key] = value;
      }
      
      data.push(addressData);
    });
    
    return data;
  }
  
  loadFormData(dataArray) {
    // 既存のフォームをクリア
    this.clearAllForms();
    
    // データからフォームを生成
    dataArray.forEach(data => {
      this.addForm(data);
    });
  }
  
  clearAllForms() {
    this.autoFillInstances.forEach(item => item.instance.destroy());
    this.autoFillInstances = [];
    this.container.innerHTML = '';
    this.formCount = 0;
  }
}

// 使用例
let dynamicFormManager;

document.addEventListener('DOMContentLoaded', function() {
  dynamicFormManager = new DynamicAddressFormManager('dynamic-forms-container');
  
  // 初期フォームを追加
  dynamicFormManager.addForm();
  
  // 追加ボタンのイベントリスナー
  document.getElementById('add-form-btn').addEventListener('click', function() {
    dynamicFormManager.addForm();
  });
  
  // 保存ボタンのイベントリスナー
  document.getElementById('save-btn').addEventListener('click', function() {
    const formData = dynamicFormManager.getAllFormData();
    console.log('保存するデータ:', formData);
    
    // サーバーに送信
    fetch('/save-addresses', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ addresses: formData })
    });
  });
});
```

## モーダルフォームでの実装

### 1. Bootstrap モーダル

```html
<!-- モーダルトリガー -->
<button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addressModal">
  住所を追加
</button>

<!-- モーダル -->
<div class="modal fade" id="addressModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">住所追加</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      
      <div class="modal-body">
        <form id="modal-address-form">
          <div class="mb-3">
            <label for="modal-name" class="form-label">名前</label>
            <input type="text" id="modal-name" name="name" class="form-control">
          </div>
          
          <div class="mb-3">
            <label for="modal-postal-code" class="form-label">郵便番号</label>
            <input type="text" 
                   id="modal-postal-code" 
                   name="postal_code" 
                   class="form-control postal-code-input"
                   placeholder="例: 123-4567">
          </div>
          
          <div class="mb-3">
            <label for="modal-address" class="form-label">住所</label>
            <textarea id="modal-address" 
                      name="address" 
                      class="form-control address-input"
                      rows="3"
                      placeholder="住所が自動入力されます"></textarea>
          </div>
        </form>
      </div>
      
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">キャンセル</button>
        <button type="button" class="btn btn-primary" id="save-address-btn">保存</button>
      </div>
    </div>
  </div>
</div>
```

```javascript
// モーダルフォームの管理
let modalAutoFill = null;

// モーダルが表示された時に初期化
document.addEventListener('shown.bs.modal', function(event) {
  const modal = event.target;
  
  if (modal.id === 'addressModal') {
    modalAutoFill = new PostalCodeAutoFill({
      postalCodeSelector: '#modal-postal-code',
      addressSelector: '#modal-address'
    });
    
    if (modalAutoFill.init()) {
      console.log('モーダル内の郵便番号自動入力機能を初期化しました');
    }
  }
});

// モーダルが閉じられた時にクリーンアップ
document.addEventListener('hidden.bs.modal', function(event) {
  const modal = event.target;
  
  if (modal.id === 'addressModal' && modalAutoFill) {
    modalAutoFill.destroy();
    modalAutoFill = null;
    
    // フォームをリセット
    document.getElementById('modal-address-form').reset();
  }
});

// 保存ボタンの処理
document.getElementById('save-address-btn').addEventListener('click', function() {
  const form = document.getElementById('modal-address-form');
  const formData = new FormData(form);
  
  // バリデーション
  const name = formData.get('name');
  const postalCode = formData.get('postal_code');
  const address = formData.get('address');
  
  if (!name || !postalCode || !address) {
    alert('すべての項目を入力してください。');
    return;
  }
  
  // データを保存
  saveAddressData({
    name: name,
    postal_code: postalCode,
    address: address
  });
  
  // モーダルを閉じる
  const modal = bootstrap.Modal.getInstance(document.getElementById('addressModal'));
  modal.hide();
});

function saveAddressData(data) {
  // サーバーに送信またはローカルストレージに保存
  fetch('/addresses', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({ address: data })
  })
  .then(response => response.json())
  .then(result => {
    console.log('住所が保存されました:', result);
    // 必要に応じてページを更新またはリストを更新
    location.reload();
  })
  .catch(error => {
    console.error('保存エラー:', error);
    alert('保存に失敗しました。');
  });
}
```

## 既存フォームへの追加

### 1. 段階的な追加

既存のフォームに郵便番号自動入力機能を段階的に追加する方法：

```javascript
// 既存フォームの段階的アップグレード
function upgradeExistingForm() {
  // 1. 既存のフィールドを確認
  const existingPostalCode = document.querySelector('#existing_postal_code');
  const existingAddress = document.querySelector('#existing_address');
  
  if (!existingPostalCode || !existingAddress) {
    console.warn('必要なフィールドが見つかりません');
    return false;
  }
  
  // 2. 必要なクラスを追加
  existingPostalCode.classList.add('postal-code-input');
  existingAddress.classList.add('address-input');
  
  // 3. プレースホルダーを更新
  if (!existingPostalCode.placeholder) {
    existingPostalCode.placeholder = '例: 123-4567';
  }
  
  if (!existingAddress.placeholder) {
    existingAddress.placeholder = '住所が自動入力されます';
  }
  
  // 4. 郵便番号自動入力機能を初期化
  const autoFill = new PostalCodeAutoFill({
    postalCodeSelector: '#existing_postal_code',
    addressSelector: '#existing_address'
  });
  
  const result = autoFill.init();
  
  if (result) {
    console.log('既存フォームに郵便番号自動入力機能を追加しました');
    
    // 5. 成功通知を表示（オプション）
    showUpgradeNotification();
  }
  
  return result;
}

function showUpgradeNotification() {
  const notification = document.createElement('div');
  notification.className = 'alert alert-info alert-dismissible fade show';
  notification.innerHTML = `
    <strong>機能が追加されました！</strong> 
    郵便番号を入力すると自動的に住所が入力されます。
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `;
  
  // フォームの上部に通知を表示
  const form = document.querySelector('form');
  if (form) {
    form.insertBefore(notification, form.firstChild);
  }
  
  // 5秒後に自動的に非表示
  setTimeout(() => {
    if (notification.parentNode) {
      notification.remove();
    }
  }, 5000);
}

// 使用例
document.addEventListener('DOMContentLoaded', function() {
  // 特定のページでのみ実行
  if (window.location.pathname.includes('/legacy-form')) {
    upgradeExistingForm();
  }
});
```

### 2. 互換性を保った追加

```javascript
// 既存の機能を壊さずに追加
function addPostalCodeFeatureCompatibly() {
  // 既存のイベントリスナーを保持
  const existingPostalCode = document.querySelector('#postal_code');
  const existingAddress = document.querySelector('#address');
  
  if (!existingPostalCode || !existingAddress) {
    return false;
  }
  
  // 既存のイベントリスナーを一時的に保存
  const existingListeners = {
    postalCode: [],
    address: []
  };
  
  // 既存のイベントを保持（可能な場合）
  const originalPostalCodeOnInput = existingPostalCode.oninput;
  const originalAddressOnInput = existingAddress.oninput;
  
  // 郵便番号自動入力機能を初期化
  const autoFill = new PostalCodeAutoFill({
    postalCodeSelector: '#postal_code',
    addressSelector: '#address'
  });
  
  if (autoFill.init()) {
    // 既存のイベントハンドラーを復元
    if (originalPostalCodeOnInput) {
      existingPostalCode.addEventListener('input', originalPostalCodeOnInput);
    }
    
    if (originalAddressOnInput) {
      existingAddress.addEventListener('input', originalAddressOnInput);
    }
    
    console.log('互換性を保って郵便番号自動入力機能を追加しました');
    return true;
  }
  
  return false;
}
```

## 特殊なケースでの実装

### 1. 条件付きフィールド

```javascript
// 条件によって表示されるフィールドでの実装
class ConditionalAddressForm {
  constructor() {
    this.autoFillInstance = null;
    this.setupConditionalLogic();
  }
  
  setupConditionalLogic() {
    const needsAddressCheckbox = document.getElementById('needs-address');
    const addressSection = document.getElementById('address-section');
    
    if (needsAddressCheckbox && addressSection) {
      needsAddressCheckbox.addEventListener('change', (e) => {
        if (e.target.checked) {
          this.showAddressSection();
        } else {
          this.hideAddressSection();
        }
      });
      
      // 初期状態の設定
      if (needsAddressCheckbox.checked) {
        this.showAddressSection();
      }
    }
  }
  
  showAddressSection() {
    const addressSection = document.getElementById('address-section');
    addressSection.style.display = 'block';
    
    // 郵便番号自動入力機能を初期化
    if (!this.autoFillInstance) {
      this.autoFillInstance = new PostalCodeAutoFill({
        postalCodeSelector: '#conditional-postal-code',
        addressSelector: '#conditional-address'
      });
      this.autoFillInstance.init();
    }
  }
  
  hideAddressSection() {
    const addressSection = document.getElementById('address-section');
    addressSection.style.display = 'none';
    
    // フィールドをクリア
    const postalCodeField = document.getElementById('conditional-postal-code');
    const addressField = document.getElementById('conditional-address');
    
    if (postalCodeField) postalCodeField.value = '';
    if (addressField) addressField.value = '';
    
    // AutoFillインスタンスは保持（再表示時に再利用）
  }
}

// 使用例
document.addEventListener('DOMContentLoaded', function() {
  new ConditionalAddressForm();
});
```

### 2. ステップフォーム

```javascript
// マルチステップフォームでの実装
class StepFormManager {
  constructor() {
    this.currentStep = 1;
    this.autoFillInstances = {};
    this.setupStepNavigation();
  }
  
  setupStepNavigation() {
    document.querySelectorAll('.step-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const targetStep = parseInt(e.target.dataset.step);
        this.goToStep(targetStep);
      });
    });
  }
  
  goToStep(stepNumber) {
    // 現在のステップを非表示
    document.querySelector(`#step-${this.currentStep}`).style.display = 'none';
    
    // 新しいステップを表示
    document.querySelector(`#step-${stepNumber}`).style.display = 'block';
    
    // 住所入力ステップの場合、郵便番号自動入力機能を初期化
    if (stepNumber === 3 && !this.autoFillInstances[stepNumber]) {
      this.autoFillInstances[stepNumber] = new PostalCodeAutoFill({
        postalCodeSelector: `#step-${stepNumber} .postal-code-input`,
        addressSelector: `#step-${stepNumber} .address-input`
      });
      this.autoFillInstances[stepNumber].init();
    }
    
    this.currentStep = stepNumber;
    this.updateStepIndicator();
  }
  
  updateStepIndicator() {
    document.querySelectorAll('.step-indicator').forEach((indicator, index) => {
      if (index + 1 === this.currentStep) {
        indicator.classList.add('active');
      } else {
        indicator.classList.remove('active');
      }
    });
  }
}

// 使用例
document.addEventListener('DOMContentLoaded', function() {
  new StepFormManager();
});
```

## まとめ

郵便番号自動住所入力機能は、様々なフォームタイプに対応できる柔軟な設計になっています。このドキュメントで紹介した実装パターンを参考に、プロジェクトの要件に応じて適切な方法を選択してください。

### 実装のポイント

1. **セレクターの適切な設定**: フォームの構造に応じたセレクターの選択
2. **ライフサイクル管理**: 動的フォームでのインスタンスの作成と削除
3. **イベントハンドリング**: 既存の機能との競合を避ける
4. **ユーザビリティ**: 直感的で使いやすいインターフェースの提供

これらの実装例を参考に、ユーザーにとって最適な住所入力体験を提供してください。