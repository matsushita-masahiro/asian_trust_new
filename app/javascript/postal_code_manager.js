/**
 * PostalCodeManager - 郵便番号自動入力機能の管理
 */
import PostalCodeAutoFill from "postal_code_auto_fill";

class PostalCodeManager {
  constructor() {
    this.instances = [];
  }

  init() {
    try {
      // 既存のインスタンスをクリーンアップ
      this.cleanup();

      // data-address-type属性を持つフィールドペアを検索
      const addressTypes = ['registration', 'shipping'];

      addressTypes.forEach(addressType => {
        const postalCodeField = document.querySelector(`input[data-address-type="${addressType}"].postal-code-input`);
        const addressField = document.querySelector(`textarea[data-address-type="${addressType}"].address-input`);

        console.log(`🔍 Searching for ${addressType} fields:`, {
          postalCodeSelector: `input[data-address-type="${addressType}"].postal-code-input`,
          addressSelector: `textarea[data-address-type="${addressType}"].address-input`,
          postalCodeField: postalCodeField,
          addressField: addressField,
          postalCodeVisible: postalCodeField ? getComputedStyle(postalCodeField).display !== 'none' : false,
          addressVisible: addressField ? getComputedStyle(addressField).display !== 'none' : false
        });

        if (postalCodeField && addressField) {
          if (!postalCodeField.dataset.postalCodeInitialized) {
            // ユニークなIDを生成
            const uniqueId = `postal-code-${addressType}-${Date.now()}`;
            if (!postalCodeField.id) postalCodeField.id = `${uniqueId}-postal`;
            if (!addressField.id) addressField.id = `${uniqueId}-address`;

            try {
              console.log(`🔧 Creating PostalCodeAutoFill instance for ${addressType}:`, {
                postalCodeSelector: `#${postalCodeField.id}`,
                addressSelector: `#${addressField.id}`,
                postalCodeFieldValue: postalCodeField.value,
                addressFieldValue: addressField.value,
                postalCodeFieldVisible: getComputedStyle(postalCodeField).display !== 'none',
                addressFieldVisible: getComputedStyle(addressField).display !== 'none'
              });

              const instance = new PostalCodeAutoFill({
                postalCodeSelector: `#${postalCodeField.id}`,
                addressSelector: `#${addressField.id}`
              });

              if (instance.init()) {
                this.instances.push(instance);
                postalCodeField.dataset.postalCodeInitialized = 'true';
                console.log(`✅ PostalCodeAutoFill initialized for ${addressType} address`);
              } else {
                console.log(`❌ Failed to initialize PostalCodeAutoFill for ${addressType} address`);
              }
            } catch (error) {
              console.error(`❌ Error initializing PostalCodeAutoFill for ${addressType}:`, error);
            }
          } else {
            console.log(`⚠️ ${addressType} address field already initialized`);
          }
        } else {
          console.log(`📝 No ${addressType} address fields found`);
        }
      });

      // 一般的な郵便番号フィールド用（data-address-type属性がない場合）
      this.initGeneralFields();

      if (this.instances.length === 0) {
        console.log("📝 No postal code fields found for initialization");
      }

      return true;
    } catch (error) {
      console.error("❌ PostalCodeManager initialization error:", error);
      return false;
    }
  }

  initGeneralFields() {
    const generalPostalCodeFields = document.querySelectorAll('input[name*="postal_code"]:not([data-address-type]), .postal-code-input:not([data-address-type])');
    const generalAddressFields = document.querySelectorAll('textarea[name*="address"]:not([data-address-type]), .address-input:not([data-address-type])');

    for (let i = 0; i < Math.min(generalPostalCodeFields.length, generalAddressFields.length); i++) {
      const postalCodeField = generalPostalCodeFields[i];
      const addressField = generalAddressFields[i];

      if (!postalCodeField.dataset.postalCodeInitialized) {
        // ユニークなIDを生成
        const uniqueId = `postal-code-general-${Date.now()}-${i}`;
        if (!postalCodeField.id) postalCodeField.id = `${uniqueId}-postal`;
        if (!addressField.id) addressField.id = `${uniqueId}-address`;

        const instance = new PostalCodeAutoFill({
          postalCodeSelector: `#${postalCodeField.id}`,
          addressSelector: `#${addressField.id}`
        });

        if (instance.init()) {
          this.instances.push(instance);
          postalCodeField.dataset.postalCodeInitialized = 'true';
          console.log(`✅ PostalCodeAutoFill initialized for general field pair ${i + 1}`);
        }
      }
    }
  }

  cleanup() {
    console.log(`🧹 Cleaning up ${this.instances.length} existing instances`);
    
    this.instances.forEach(instance => {
      if (instance && typeof instance.destroy === 'function') {
        instance.destroy();
      }
    });
    this.instances = [];

    // 既存の初期化フラグをクリア
    const existingFields = document.querySelectorAll('[data-postal-code-initialized]');
    existingFields.forEach(field => {
      console.log(`🧹 Clearing initialization flag for field:`, field.id || field.name);
      delete field.dataset.postalCodeInitialized;
    });
  }

  setupAddressEditListeners() {
    // 住所編集ボタンを監視
    document.addEventListener('click', (event) => {
      // 住所編集ボタンがクリックされた場合
      if (event.target.matches('button[onclick*="toggleAddressEdit"]')) {
        console.log('📝 Address edit button clicked, reinitializing postal code auto fill');
        
        // 少し遅延してから郵便番号自動入力を再初期化
        setTimeout(() => {
          this.init();
        }, 100);
      }
    });

    // MutationObserverで住所編集フォームの表示状態を監視
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
          const target = mutation.target;
          
          // 住所編集フォームが表示された場合
          if (target.classList.contains('address-edit-form') && 
              target.style.display !== 'none') {
            console.log('📝 Address edit form shown, reinitializing postal code auto fill');
            
            setTimeout(() => {
              this.init();
            }, 100);
          }
        }
      });
    });

    // 住所編集フォームを監視対象に追加
    const addressEditForms = document.querySelectorAll('.address-edit-form');
    addressEditForms.forEach(form => {
      observer.observe(form, {
        attributes: true,
        attributeFilter: ['style']
      });
    });

    console.log('✅ Address edit listeners setup complete');
  }

  // デバッグ用テスト関数
  test() {
    console.log('🧪 Testing PostalCodeAutoFill functionality');
    
    const postalCodeFields = document.querySelectorAll('.postal-code-input');
    const addressFields = document.querySelectorAll('.address-input');
    
    console.log('🔍 Found fields:', {
      postalCodeFields: postalCodeFields.length,
      addressFields: addressFields.length,
      instances: this.instances.length
    });

    postalCodeFields.forEach((field, index) => {
      console.log(`📮 Postal code field ${index}:`, {
        id: field.id,
        name: field.name,
        value: field.value,
        visible: getComputedStyle(field).display !== 'none',
        initialized: field.dataset.postalCodeInitialized,
        hasEventListeners: field.hasAttribute('data-postal-code-initialized')
      });
    });

    addressFields.forEach((field, index) => {
      console.log(`🏠 Address field ${index}:`, {
        id: field.id,
        name: field.name,
        value: field.value,
        visible: getComputedStyle(field).display !== 'none'
      });
    });
  }
}

export default PostalCodeManager;