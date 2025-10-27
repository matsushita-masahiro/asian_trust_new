/**
 * PostalCodeAutoFill - 郵便番号自動住所入力機能
 * 
 * 郵便番号を入力すると自動的に住所を取得して入力フィールドに反映するクラス
 */
class PostalCodeAutoFill {
  /**
   * コンストラクター
   * @param {Object} options - 設定オプション
   * @param {string} options.postalCodeSelector - 郵便番号フィールドのセレクター
   * @param {string} options.addressSelector - 住所フィールドのセレクター
   * @param {string} options.apiUrl - 郵便番号API URL
   * @param {number} options.debounceDelay - デバウンス遅延時間（ミリ秒）
   * @param {boolean} options.enableCache - キャッシュ機能の有効/無効
   * @param {boolean} options.showLoadingIndicator - ローディング表示の有効/無効
   * @param {number} options.apiTimeout - APIタイムアウト時間（ミリ秒）
   */
  constructor(options = {}) {
    // デフォルト設定
    this.config = {
      postalCodeSelector: options.postalCodeSelector || 'input[name*="postal_code"]',
      addressSelector: options.addressSelector || 'textarea[name*="address"]',
      apiUrl: options.apiUrl || 'https://zipcloud.ibsnet.co.jp/api/search',
      debounceDelay: options.debounceDelay || 500,
      enableCache: options.enableCache !== false, // デフォルトtrue
      showLoadingIndicator: options.showLoadingIndicator !== false, // デフォルトtrue
      apiTimeout: options.apiTimeout || 5000
    };

    // 内部状態管理
    this.cache = new Map(); // 郵便番号検索結果のキャッシュ
    this.debounceTimer = null; // デバウンス用タイマー
    this.loadingIndicator = null; // ローディング表示要素
    this.errorDisplay = null; // エラー表示要素
    
    // キャッシュ管理設定
    this.cacheExpirationTime = 30 * 60 * 1000; // キャッシュ有効期限（30分）
    this.maxCacheSize = 100; // 最大キャッシュサイズ
    this.cacheCleanupInterval = 5 * 60 * 1000; // キャッシュクリーンアップ間隔（5分）
    this.cacheCleanupTimer = null; // キャッシュクリーンアップタイマー
    
    // API呼び出し制限管理
    this.apiCallHistory = []; // API呼び出し履歴
    this.maxApiCallsPerMinute = 30; // 1分間の最大API呼び出し回数
    this.apiCallWindow = 60000; // API呼び出し制限の時間窓（ミリ秒）
    
    // 手動編集状態管理
    this.isManuallyEdited = false; // 手動編集フラグ
    this.lastAutoFilledAddress = ''; // 最後に自動入力された住所
    this.originalAddressValue = ''; // 手動編集前の住所値
    this.manualEditStartTime = null; // 手動編集開始時刻
    this.addressEditHistory = []; // 住所編集履歴

    // DOM要素の参照
    this.postalCodeField = null;
    this.addressField = null;

    console.log('PostalCodeAutoFill initialized with config:', this.config);
  }

  /**
   * 初期化メソッド
   * DOM要素を取得し、イベントリスナーを設定する
   */
  init() {
    try {
      // DOM要素を取得
      this.postalCodeField = document.querySelector(this.config.postalCodeSelector);
      this.addressField = document.querySelector(this.config.addressSelector);

      if (!this.postalCodeField) {
        console.warn('PostalCodeAutoFill: 郵便番号フィールドが見つかりません:', this.config.postalCodeSelector);
        return false;
      }

      if (!this.addressField) {
        console.warn('PostalCodeAutoFill: 住所フィールドが見つかりません:', this.config.addressSelector);
        return false;
      }

      // UI要素を作成
      this.createUIElements();

      // イベントリスナーを設定
      this.setupEventListeners();

      // アクセシビリティ対応
      this.setupAccessibility();

      // キーボードショートカット設定
      this.setupKeyboardShortcuts();

      // キャッシュクリーンアップタイマーを開始
      this.startCacheCleanup();

      console.log('PostalCodeAutoFill: 初期化完了');
      return true;
    } catch (error) {
      console.error('PostalCodeAutoFill: 初期化エラー:', error);
      return false;
    }
  }

  /**
   * UI要素（ローディング、エラー表示）を作成
   */
  createUIElements() {
    // 既存の要素があれば削除
    this.removeUIElements();

    // ローディングインジケーター作成
    if (this.config.showLoadingIndicator) {
      this.loadingIndicator = document.createElement('div');
      this.loadingIndicator.className = 'postal-code-loading';
      this.loadingIndicator.style.display = 'none';
      this.loadingIndicator.innerHTML = `
        <small class="text-muted">
          <i class="fas fa-spinner fa-spin"></i> 住所を取得中...
        </small>
      `;
    }

    // エラー表示要素作成
    this.errorDisplay = document.createElement('div');
    this.errorDisplay.className = 'postal-code-error';
    this.errorDisplay.style.display = 'none';
    this.errorDisplay.innerHTML = `
      <small class="text-danger">
        <i class="fas fa-exclamation-triangle"></i> 
        <span class="error-message"></span>
      </small>
    `;

    // 郵便番号フィールドの後に挿入
    const parent = this.postalCodeField.parentNode;
    if (this.loadingIndicator) {
      parent.insertBefore(this.loadingIndicator, this.postalCodeField.nextSibling);
    }
    parent.insertBefore(this.errorDisplay, this.postalCodeField.nextSibling);
  }

  /**
   * UI要素を削除
   */
  removeUIElements() {
    if (this.loadingIndicator && this.loadingIndicator.parentNode) {
      this.loadingIndicator.parentNode.removeChild(this.loadingIndicator);
    }
    if (this.errorDisplay && this.errorDisplay.parentNode) {
      this.errorDisplay.parentNode.removeChild(this.errorDisplay);
    }
  }

  /**
   * イベントリスナーを設定
   */
  setupEventListeners() {
    // イベントハンドラーを保存（removeEventListenerで使用するため）
    this.handlePostalCodeInputBound = (event) => this.handlePostalCodeInput(event);
    this.handleAddressManualEditBound = (event) => this.handleAddressManualEdit(event);
    this.handleAddressFocusBound = () => this.handleAddressFocus();
    this.handleAddressBlurBound = () => this.handleAddressBlur();
    this.hideErrorBound = () => this.hideError();

    // 郵便番号入力イベント
    this.postalCodeField.addEventListener('input', this.handlePostalCodeInputBound);

    // 住所フィールドの手動編集検知
    this.addressField.addEventListener('input', this.handleAddressManualEditBound);

    // 住所フィールドのフォーカス時
    this.addressField.addEventListener('focus', this.handleAddressFocusBound);

    // 住所フィールドのフォーカス離脱時
    this.addressField.addEventListener('blur', this.handleAddressBlurBound);

    // フォーカス時のエラークリア
    this.postalCodeField.addEventListener('focus', this.hideErrorBound);
  }

  /**
   * 郵便番号入力イベントハンドラー
   * デバウンス機能付きで郵便番号の検証と住所取得を行う
   * @param {Event} event - 入力イベント
   */
  handlePostalCodeInput(event) {
    const inputValue = event.target.value;
    
    // デバウンスタイマーをクリア
    this.clearDebounceTimer();

    // エラー表示をクリア
    this.hideError();

    // 入力値が空の場合は住所フィールドもクリア
    if (!inputValue.trim()) {
      this.clearAddressField();
      return;
    }

    // デバウンス処理 - 連続API呼び出しを制御
    this.debounceTimer = setTimeout(() => {
      this.processPostalCodeInput(inputValue);
    }, this.config.debounceDelay);

    // デバウンス中の視覚的フィードバック
    this.showDebounceIndicator();
  }

  /**
   * デバウンスタイマーをクリア
   */
  clearDebounceTimer() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
    this.hideDebounceIndicator();
  }

  /**
   * デバウンス中の視覚的インジケーターを表示
   */
  showDebounceIndicator() {
    if (!this.postalCodeField) return;

    // 軽微な視覚的フィードバック（ユーザー体験を損なわない程度）
    this.postalCodeField.classList.add('postal-code-debouncing');
    this.postalCodeField.style.borderColor = '#6c757d';
    this.postalCodeField.style.transition = 'border-color 0.2s ease';
  }

  /**
   * デバウンス中の視覚的インジケーターを非表示
   */
  hideDebounceIndicator() {
    if (!this.postalCodeField) return;

    this.postalCodeField.classList.remove('postal-code-debouncing');
    this.postalCodeField.style.borderColor = '';
    this.postalCodeField.style.transition = '';
  }

  /**
   * 郵便番号入力の処理
   * バリデーションを行い、有効な場合は住所を取得
   * @param {string} inputValue - 入力された郵便番号
   */
  async processPostalCodeInput(inputValue) {
    try {
      // デバウンス完了の視覚的フィードバックをクリア
      this.hideDebounceIndicator();

      // 郵便番号をバリデーション
      const postalCode = this.validateAndFormatPostalCode(inputValue);
      
      if (!postalCode) {
        return; // バリデーションエラーの場合は何もしない
      }

      // 7桁の郵便番号が完成した場合のみ住所を取得
      if (postalCode.length === 7) {
        // API呼び出し制限チェック
        if (this.isApiCallAllowed()) {
          await this.fetchAndUpdateAddress(postalCode);
        } else {
          this.showError('API呼び出し制限に達しました。しばらくお待ちください');
          console.warn('PostalCodeAutoFill: API呼び出し制限により処理をスキップ');
        }
      }
    } catch (error) {
      console.error('PostalCodeAutoFill: 郵便番号処理エラー:', error);
      this.showError('住所の取得中にエラーが発生しました');
    }
  }

  /**
   * 郵便番号のバリデーションとフォーマット
   * ハイフンあり/なし両方の形式に対応
   * @param {string} input - 入力された郵便番号
   * @returns {string|null} フォーマット済み郵便番号（7桁の数字）またはnull
   */
  validateAndFormatPostalCode(input) {
    if (!input || typeof input !== 'string') {
      return null;
    }

    // 数字とハイフンのみを抽出
    const cleaned = input.replace(/[^\d-]/g, '');
    
    // ハイフンを除去して数字のみにする
    const numbersOnly = cleaned.replace(/-/g, '');

    // 数字以外が含まれている場合はエラー
    if (!/^\d*$/.test(numbersOnly)) {
      if (numbersOnly.length > 0) {
        this.showError('郵便番号は数字のみで入力してください');
      }
      return null;
    }

    // 長さチェック
    if (numbersOnly.length > 7) {
      this.showError('郵便番号は7桁以内で入力してください');
      return null;
    }

    // 7桁未満の場合は処理を続行（入力中の可能性）
    if (numbersOnly.length < 7) {
      return numbersOnly;
    }

    // ハイフン付きの形式チェック（123-4567）
    if (cleaned.includes('-')) {
      const parts = cleaned.split('-');
      if (parts.length === 2 && parts[0].length === 3 && parts[1].length === 4) {
        return numbersOnly; // 正しい形式
      } else if (parts.length > 2 || (parts.length === 2 && (parts[0].length !== 3 || parts[1].length !== 4))) {
        this.showError('郵便番号の形式が正しくありません（例: 123-4567）');
        return null;
      }
    }

    return numbersOnly;
  }

  /**
   * 郵便番号の形式チェック
   * @param {string} postalCode - 郵便番号（数字のみ7桁）
   * @returns {boolean} 有効な郵便番号かどうか
   */
  isValidPostalCodeFormat(postalCode) {
    // 7桁の数字であることを確認
    return /^\d{7}$/.test(postalCode);
  }

  /**
   * 郵便番号から住所を取得して更新
   * @param {string} postalCode - 7桁の郵便番号
   */
  async fetchAndUpdateAddress(postalCode) {
    try {
      // キャッシュから確認
      if (this.config.enableCache) {
        const cachedData = this.getCachedAddress(postalCode);
        if (cachedData) {
          console.log('PostalCodeAutoFill: キャッシュから住所を取得', { postalCode });
          this.updateAddressField(cachedData);
          this.showSuccessState();
          return;
        }
      }

      // ローディング表示
      this.showLoading();

      // API呼び出し
      const addressData = await this.fetchAddress(postalCode);
      
      if (addressData) {
        // キャッシュに保存
        if (this.config.enableCache) {
          this.setCachedAddress(postalCode, addressData);
        }
        
        // 住所フィールドを更新
        this.updateAddressField(addressData);
        
        // 成功状態を表示
        this.showSuccessState();
      }
    } catch (error) {
      console.error('PostalCodeAutoFill: 住所取得エラー:', error);
      this.showError('住所の取得に失敗しました。手動で入力してください');
    } finally {
      this.hideLoading();
    }
  }

  /**
   * zipcloud APIから住所を取得
   * @param {string} postalCode - 7桁の郵便番号
   * @returns {Promise<Object|null>} 住所データまたはnull
   */
  async fetchAddress(postalCode) {
    try {
      // API呼び出し履歴を記録
      this.recordApiCall();

      // APIリクエストURL構築
      const url = `${this.config.apiUrl}?zipcode=${postalCode}`;
      
      // AbortControllerでタイムアウト制御
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.config.apiTimeout);

      console.log('PostalCodeAutoFill: API呼び出し開始', { postalCode, url });

      // API呼び出し
      const response = await fetch(url, {
        method: 'GET',
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
        }
      });

      clearTimeout(timeoutId);

      // HTTPステータスチェック
      if (!response.ok) {
        throw new Error(`HTTP Error: ${response.status} ${response.statusText}`);
      }

      // レスポンスをJSONとしてパース
      const data = await response.json();
      
      console.log('PostalCodeAutoFill: API呼び出し成功', { postalCode, data });

      // APIレスポンスの検証と住所データ抽出
      return this.parseAddressResponse(data, postalCode);

    } catch (error) {
      console.error('PostalCodeAutoFill: API呼び出しエラー', { postalCode, error });

      if (error.name === 'AbortError') {
        throw new Error('APIリクエストがタイムアウトしました');
      } else if (error instanceof TypeError && error.message.includes('fetch')) {
        throw new Error('ネットワークエラーが発生しました');
      } else {
        throw error;
      }
    }
  }

  /**
   * zipcloud APIレスポンスをパースして住所データを抽出
   * @param {Object} response - APIレスポンス
   * @param {string} postalCode - リクエストした郵便番号
   * @returns {Object|null} 住所データまたはnull
   */
  parseAddressResponse(response, postalCode) {
    try {
      // レスポンス構造の検証
      if (!response || typeof response !== 'object') {
        throw new Error('無効なAPIレスポンス形式');
      }

      // エラーメッセージがある場合
      if (response.message) {
        throw new Error(`API Error: ${response.message}`);
      }

      // ステータスコードチェック
      if (response.status && response.status !== 200) {
        throw new Error(`API Status Error: ${response.status}`);
      }

      // 結果データの確認
      if (!response.results || !Array.isArray(response.results) || response.results.length === 0) {
        this.showError('該当する住所が見つかりませんでした');
        return null;
      }

      // 最初の結果を使用（通常は1件のみ）
      const result = response.results[0];
      
      // 必要なフィールドの存在確認
      if (!result.address1 || !result.address2) {
        throw new Error('住所データが不完全です');
      }

      // 住所データを構築
      const addressData = {
        prefecture: result.address1 || '', // 都道府県
        city: result.address2 || '',       // 市区町村
        town: result.address3 || '',       // 町域
        fullAddress: this.buildFullAddress(result.address1, result.address2, result.address3),
        zipcode: result.zipcode || postalCode,
        prefcode: result.prefcode || '',
        kana: {
          prefecture: result.kana1 || '',
          city: result.kana2 || '',
          town: result.kana3 || ''
        }
      };

      console.log('PostalCodeAutoFill: 住所データ取得成功:', addressData);
      return addressData;

    } catch (error) {
      console.error('PostalCodeAutoFill: レスポンス解析エラー:', error);
      
      // ユーザー向けエラーメッセージ
      if (error.message.includes('該当する住所が見つかりません')) {
        this.showError('該当する住所が見つかりませんでした');
      } else {
        this.showError('住所データの処理中にエラーが発生しました');
      }
      
      return null;
    }
  }

  /**
   * 完全な住所文字列を構築
   * @param {string} prefecture - 都道府県
   * @param {string} city - 市区町村
   * @param {string} town - 町域
   * @returns {string} 結合された住所文字列
   */
  buildFullAddress(prefecture, city, town) {
    const parts = [prefecture, city, town].filter(part => part && part.trim());
    return parts.join('');
  }

  /**
   * 住所フィールドを自動更新
   * @param {Object} addressData - 住所データ
   */
  updateAddressField(addressData) {
    if (!this.addressField || !addressData) {
      return;
    }

    try {
      // 手動編集されている場合の処理
      if (this.isManuallyEdited) {
        // 手動編集後の自動上書き制御
        if (!this.shouldOverrideManualEdit()) {
          console.log('PostalCodeAutoFill: 手動編集を保持するため自動更新をスキップ');
          return;
        }

        // ユーザーの入力意図を保持して更新
        this.updateAddressPreservingUserIntent(addressData);
      } else {
        // 通常の自動更新
        const fullAddress = addressData.fullAddress || this.buildFullAddress(
          addressData.prefecture,
          addressData.city,
          addressData.town
        );

        // 既存の値を上書き
        this.addressField.value = fullAddress;

        // 自動入力された住所を記録
        this.lastAutoFilledAddress = fullAddress;

        // 手動編集フラグをリセット
        this.resetManualEditState();
      }

      // 視覚的フィードバック（フィールドを一時的にハイライト）
      this.highlightAddressField();

      // カスタムイベントを発火（他のスクリプトが住所更新を検知できるように）
      this.dispatchAddressUpdateEvent(addressData);

      console.log('PostalCodeAutoFill: 住所フィールド更新完了:', this.addressField.value);

    } catch (error) {
      console.error('PostalCodeAutoFill: 住所フィールド更新エラー:', error);
      this.showError('住所の設定中にエラーが発生しました');
    }
  }

  /**
   * 住所フィールドを一時的にハイライト
   */
  highlightAddressField() {
    if (!this.addressField) return;

    // 元のスタイルを保存
    const originalBackground = this.addressField.style.backgroundColor;
    const originalTransition = this.addressField.style.transition;

    // ハイライト効果を適用
    this.addressField.style.transition = 'background-color 0.3s ease';
    this.addressField.style.backgroundColor = '#e8f5e8'; // 薄い緑色

    // 1秒後に元に戻す
    setTimeout(() => {
      this.addressField.style.backgroundColor = originalBackground;
      
      // さらに0.3秒後にtransitionを元に戻す
      setTimeout(() => {
        this.addressField.style.transition = originalTransition;
      }, 300);
    }, 1000);
  }

  /**
   * 住所更新イベントを発火
   * @param {Object} addressData - 住所データ
   */
  dispatchAddressUpdateEvent(addressData) {
    try {
      const event = new CustomEvent('postalCodeAutoFill:addressUpdated', {
        detail: {
          addressData: addressData,
          postalCodeField: this.postalCodeField,
          addressField: this.addressField
        },
        bubbles: true
      });

      this.addressField.dispatchEvent(event);
    } catch (error) {
      console.warn('PostalCodeAutoFill: イベント発火エラー:', error);
    }
  }

  /**
   * 住所データの各部分を取得
   * @param {Object} addressData - 住所データ
   * @returns {Object} 分離された住所部分
   */
  getAddressParts(addressData) {
    if (!addressData) return null;

    return {
      prefecture: addressData.prefecture || '',
      city: addressData.city || '',
      town: addressData.town || '',
      fullAddress: addressData.fullAddress || '',
      zipcode: addressData.zipcode || '',
      kana: addressData.kana || {}
    };
  }

  /**
   * 現在の住所を各部分に分離して解析
   * @param {string} fullAddress - 完全な住所文字列
   * @returns {Object} 分離された住所部分
   */
  parseAddressParts(fullAddress) {
    if (!fullAddress || typeof fullAddress !== 'string') {
      return {
        baseAddress: '',
        details: '',
        prefecture: '',
        city: '',
        town: '',
        streetNumber: '',
        building: ''
      };
    }

    // 自動入力された基本住所部分を特定
    const baseAddress = this.lastAutoFilledAddress || '';
    let details = '';
    let streetNumber = '';
    let building = '';

    if (baseAddress && fullAddress.startsWith(baseAddress)) {
      // 基本住所以降の部分を詳細情報として抽出
      details = fullAddress.substring(baseAddress.length).trim();
      
      // 詳細情報をさらに分析（番地・建物名等）
      const detailsParts = this.parseAddressDetails(details);
      streetNumber = detailsParts.streetNumber;
      building = detailsParts.building;
    } else {
      // 基本住所が含まれていない場合は全体を詳細情報として扱う
      details = fullAddress;
    }

    return {
      baseAddress: baseAddress,
      details: details,
      prefecture: this.extractPrefecture(fullAddress),
      city: this.extractCity(fullAddress),
      town: this.extractTown(fullAddress),
      streetNumber: streetNumber,
      building: building,
      fullAddress: fullAddress
    };
  }

  /**
   * 住所詳細部分（番地・建物名等）を解析
   * @param {string} details - 詳細住所文字列
   * @returns {Object} 解析された詳細情報
   */
  parseAddressDetails(details) {
    if (!details) {
      return { streetNumber: '', building: '' };
    }

    let streetNumber = '';
    let building = '';

    // 番地パターンの正規表現（例: 1-2-3, 1丁目2番3号, 1番地2号 等）
    const streetNumberPatterns = [
      /^(\d+[-－]\d+[-－]\d+)/,  // 1-2-3 形式
      /^(\d+丁目\d+番\d+号)/,    // 1丁目2番3号 形式
      /^(\d+番地\d+号)/,         // 1番地2号 形式
      /^(\d+[-－]\d+)/,          // 1-2 形式
      /^(\d+丁目\d+番)/,         // 1丁目2番 形式
      /^(\d+番地)/,              // 1番地 形式
      /^(\d+丁目)/,              // 1丁目 形式
      /^(\d+)/                   // 数字のみ
    ];

    for (const pattern of streetNumberPatterns) {
      const match = details.match(pattern);
      if (match) {
        streetNumber = match[1];
        building = details.substring(match[0].length).trim();
        break;
      }
    }

    // 番地が見つからない場合は全体を建物名として扱う
    if (!streetNumber) {
      building = details;
    }

    return { streetNumber, building };
  }

  /**
   * 住所から都道府県を抽出
   * @param {string} address - 住所文字列
   * @returns {string} 都道府県名
   */
  extractPrefecture(address) {
    if (!address) return '';

    const prefecturePattern = /(北海道|青森県|岩手県|宮城県|秋田県|山形県|福島県|茨城県|栃木県|群馬県|埼玉県|千葉県|東京都|神奈川県|新潟県|富山県|石川県|福井県|山梨県|長野県|岐阜県|静岡県|愛知県|三重県|滋賀県|京都府|大阪府|兵庫県|奈良県|和歌山県|鳥取県|島根県|岡山県|広島県|山口県|徳島県|香川県|愛媛県|高知県|福岡県|佐賀県|長崎県|熊本県|大分県|宮崎県|鹿児島県|沖縄県)/;
    const match = address.match(prefecturePattern);
    return match ? match[1] : '';
  }

  /**
   * 住所から市区町村を抽出
   * @param {string} address - 住所文字列
   * @returns {string} 市区町村名
   */
  extractCity(address) {
    if (!address) return '';

    // 都道府県を除去
    const prefecture = this.extractPrefecture(address);
    let remaining = prefecture ? address.replace(prefecture, '') : address;

    // 市区町村パターンの正規表現
    const cityPattern = /^([^0-9]*?[市区町村郡])/;
    const match = remaining.match(cityPattern);
    return match ? match[1] : '';
  }

  /**
   * 住所から町域を抽出
   * @param {string} address - 住所文字列
   * @returns {string} 町域名
   */
  extractTown(address) {
    if (!address) return '';

    const prefecture = this.extractPrefecture(address);
    const city = this.extractCity(address);
    
    let remaining = address;
    if (prefecture) remaining = remaining.replace(prefecture, '');
    if (city) remaining = remaining.replace(city, '');

    // 数字が始まるまでの部分を町域として抽出
    const townPattern = /^([^0-9]*)/;
    const match = remaining.match(townPattern);
    return match ? match[1].trim() : '';
  }

  /**
   * 住所詳細情報を追加
   * @param {string} details - 追加する詳細情報（番地・建物名等）
   */
  addAddressDetails(details) {
    if (!this.addressField || !details) return;

    const currentAddress = this.getCurrentAddress();
    const baseAddress = this.lastAutoFilledAddress || '';

    // 基本住所がある場合は、それに詳細情報を追加
    if (baseAddress) {
      // 既存の詳細情報を置き換えるか追加するかを判定
      let newAddress;
      if (currentAddress.startsWith(baseAddress)) {
        // 既存の詳細情報を新しい詳細情報で置き換え
        newAddress = baseAddress + details;
      } else {
        // 基本住所に詳細情報を追加
        newAddress = baseAddress + details;
      }

      this.addressField.value = newAddress;
    } else {
      // 基本住所がない場合は現在の住所に追加
      this.addressField.value = currentAddress + details;
    }

    // 手動編集として記録
    this.handleAddressManualEdit({ target: this.addressField });

    // 視覚的フィードバック
    this.highlightAddressField();

    console.log('PostalCodeAutoFill: 住所詳細情報追加完了:', this.addressField.value);
  }

  /**
   * 住所の各部分を分離して表示用のオブジェクトを生成
   * @returns {Object} 表示用の住所部分オブジェクト
   */
  getDisplayAddressParts() {
    const currentAddress = this.getCurrentAddress();
    const parts = this.parseAddressParts(currentAddress);

    return {
      // 基本情報
      prefecture: parts.prefecture,
      city: parts.city,
      town: parts.town,
      
      // 詳細情報
      streetNumber: parts.streetNumber,
      building: parts.building,
      
      // 組み合わせ情報
      baseAddress: parts.baseAddress,
      details: parts.details,
      fullAddress: parts.fullAddress,
      
      // 状態情報
      isAutoFilled: !!this.lastAutoFilledAddress,
      isManuallyEdited: this.isManuallyEdited,
      
      // 表示用フォーマット
      formatted: this.formatAddressForDisplay(parts)
    };
  }

  /**
   * 住所を表示用にフォーマット
   * @param {Object} parts - 住所部分オブジェクト
   * @returns {Object} フォーマット済み表示用オブジェクト
   */
  formatAddressForDisplay(parts) {
    return {
      // 基本住所部分（自動入力）
      base: `${parts.prefecture}${parts.city}${parts.town}`,
      
      // 詳細部分（手動入力）
      details: parts.details,
      
      // 番地部分
      streetNumber: parts.streetNumber,
      
      // 建物名部分
      building: parts.building,
      
      // 完全な住所
      full: parts.fullAddress,
      
      // 分離表示用
      separated: {
        prefecture: parts.prefecture,
        city: parts.city,
        town: parts.town,
        streetNumber: parts.streetNumber,
        building: parts.building
      }
    };
  }

  /**
   * 住所フィールドの現在の値を取得
   * @returns {string} 現在の住所フィールドの値
   */
  getCurrentAddress() {
    return this.addressField ? this.addressField.value : '';
  }

  /**
   * 住所フィールドに値が設定されているかチェック
   * @returns {boolean} 住所フィールドに値があるかどうか
   */
  hasAddressValue() {
    const currentValue = this.getCurrentAddress();
    return currentValue && currentValue.trim().length > 0;
  }

  /**
   * ローディングインジケーターを表示
   */
  showLoading() {
    if (this.loadingIndicator && this.config.showLoadingIndicator) {
      this.loadingIndicator.style.display = 'block';
      
      // エラー表示は非表示にする
      this.hideError();
      
      // 郵便番号フィールドにローディング状態のスタイルを適用
      this.setFieldLoadingState(true);
    }
  }

  /**
   * ローディングインジケーターを非表示
   */
  hideLoading() {
    if (this.loadingIndicator) {
      this.loadingIndicator.style.display = 'none';
      
      // 郵便番号フィールドのローディング状態を解除
      this.setFieldLoadingState(false);
    }
  }

  /**
   * エラーメッセージを表示
   * @param {string} message - エラーメッセージ
   */
  showError(message) {
    if (this.errorDisplay && message) {
      const errorMessageElement = this.errorDisplay.querySelector('.error-message');
      if (errorMessageElement) {
        errorMessageElement.textContent = message;
      }
      
      this.errorDisplay.style.display = 'block';
      
      // ローディング表示は非表示にする
      this.hideLoading();
      
      // 郵便番号フィールドにエラー状態のスタイルを適用
      this.setFieldErrorState(true);
      
      console.warn('PostalCodeAutoFill: エラー表示:', message);
    }
  }

  /**
   * エラーメッセージを非表示
   */
  hideError() {
    if (this.errorDisplay) {
      this.errorDisplay.style.display = 'none';
      
      // 郵便番号フィールドのエラー状態を解除
      this.setFieldErrorState(false);
    }
  }

  /**
   * 郵便番号フィールドにローディング状態のスタイルを適用/解除
   * @param {boolean} isLoading - ローディング状態かどうか
   */
  setFieldLoadingState(isLoading) {
    if (!this.postalCodeField) return;

    if (isLoading) {
      this.postalCodeField.classList.add('postal-code-loading-state');
      this.postalCodeField.style.backgroundImage = 'url("data:image/svg+xml;charset=utf8,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'16\' height=\'16\' viewBox=\'0 0 16 16\'%3E%3Cpath fill=\'%23007bff\' d=\'M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0zM7 3v6l5.25 2.52.77-1.28L9 8.5V3H7z\'/%3E%3C/svg%3E")';
      this.postalCodeField.style.backgroundRepeat = 'no-repeat';
      this.postalCodeField.style.backgroundPosition = 'right 10px center';
      this.postalCodeField.style.backgroundSize = '16px 16px';
      this.postalCodeField.style.paddingRight = '35px';
    } else {
      this.postalCodeField.classList.remove('postal-code-loading-state');
      this.postalCodeField.style.backgroundImage = '';
      this.postalCodeField.style.backgroundRepeat = '';
      this.postalCodeField.style.backgroundPosition = '';
      this.postalCodeField.style.backgroundSize = '';
      this.postalCodeField.style.paddingRight = '';
    }
  }

  /**
   * 郵便番号フィールドにエラー状態のスタイルを適用/解除
   * @param {boolean} hasError - エラー状態かどうか
   */
  setFieldErrorState(hasError) {
    if (!this.postalCodeField) return;

    if (hasError) {
      this.postalCodeField.classList.add('is-invalid', 'postal-code-error-state');
      this.postalCodeField.style.borderColor = '#dc3545';
      this.postalCodeField.style.boxShadow = '0 0 0 0.2rem rgba(220, 53, 69, 0.25)';
    } else {
      this.postalCodeField.classList.remove('is-invalid', 'postal-code-error-state');
      this.postalCodeField.style.borderColor = '';
      this.postalCodeField.style.boxShadow = '';
    }
  }

  /**
   * 成功状態の視覚的フィードバックを表示
   */
  showSuccessState() {
    if (!this.postalCodeField) return;

    // 一時的に成功状態のスタイルを適用
    const originalBorderColor = this.postalCodeField.style.borderColor;
    const originalBoxShadow = this.postalCodeField.style.boxShadow;

    this.postalCodeField.style.borderColor = '#28a745';
    this.postalCodeField.style.boxShadow = '0 0 0 0.2rem rgba(40, 167, 69, 0.25)';
    this.postalCodeField.classList.add('postal-code-success-state');

    // 2秒後に元に戻す
    setTimeout(() => {
      this.postalCodeField.style.borderColor = originalBorderColor;
      this.postalCodeField.style.boxShadow = originalBoxShadow;
      this.postalCodeField.classList.remove('postal-code-success-state');
    }, 2000);
  }

  /**
   * アクセシビリティ対応のARIA属性を設定
   */
  setupAccessibility() {
    if (!this.postalCodeField) return;

    // ARIA属性を設定
    this.postalCodeField.setAttribute('aria-describedby', 'postal-code-help postal-code-error');
    
    if (this.loadingIndicator) {
      this.loadingIndicator.setAttribute('id', 'postal-code-loading');
      this.loadingIndicator.setAttribute('aria-live', 'polite');
    }
    
    if (this.errorDisplay) {
      this.errorDisplay.setAttribute('id', 'postal-code-error');
      this.errorDisplay.setAttribute('role', 'alert');
      this.errorDisplay.setAttribute('aria-live', 'assertive');
    }
  }

  /**
   * キーボードショートカットの設定
   */
  setupKeyboardShortcuts() {
    if (!this.postalCodeField) return;

    this.postalCodeField.addEventListener('keydown', (event) => {
      // Escキーでエラーをクリア
      if (event.key === 'Escape') {
        this.hideError();
        event.preventDefault();
      }
      
      // Ctrl+Enterで強制的に住所取得を実行
      if (event.ctrlKey && event.key === 'Enter') {
        const postalCode = this.validateAndFormatPostalCode(event.target.value);
        if (postalCode && postalCode.length === 7) {
          this.fetchAndUpdateAddress(postalCode);
        }
        event.preventDefault();
      }
    });
  }

  /**
   * 住所フィールドの手動編集を処理
   * @param {Event} event - 入力イベント
   */
  handleAddressManualEdit(event) {
    const currentValue = event.target.value;
    
    // 初回の手動編集を検知
    if (!this.isManuallyEdited) {
      this.isManuallyEdited = true;
      this.manualEditStartTime = Date.now();
      this.originalAddressValue = this.lastAutoFilledAddress || '';
      
      console.log('PostalCodeAutoFill: 手動編集開始を検知');
    }

    // 編集履歴を記録
    this.recordAddressEdit(currentValue);

    // 手動編集状態の視覚的フィードバック
    this.showManualEditIndicator();
  }

  /**
   * 住所フィールドのフォーカス時の処理
   */
  handleAddressFocus() {
    // フォーカス時に現在の値を記録（編集前の状態として）
    if (!this.isManuallyEdited) {
      this.originalAddressValue = this.addressField.value;
    }
  }

  /**
   * 住所フィールドのフォーカス離脱時の処理
   */
  handleAddressBlur() {
    // 手動編集の確定処理
    if (this.isManuallyEdited) {
      this.finalizeManualEdit();
    }
  }

  /**
   * 住所編集履歴を記録
   * @param {string} value - 現在の住所値
   */
  recordAddressEdit(value) {
    const timestamp = Date.now();
    
    // 履歴の最大件数を制限（メモリ使用量制御）
    if (this.addressEditHistory.length >= 10) {
      this.addressEditHistory.shift(); // 古い履歴を削除
    }

    this.addressEditHistory.push({
      value: value,
      timestamp: timestamp,
      isManualEdit: true
    });
  }

  /**
   * 手動編集後の自動上書きを制御するかどうかを判定
   * @returns {boolean} 自動上書きを許可するかどうか
   */
  shouldOverrideManualEdit() {
    // 手動編集されていない場合は常に上書き許可
    if (!this.isManuallyEdited) {
      return true;
    }

    // 手動編集から一定時間経過している場合は上書き許可
    const timeSinceEdit = Date.now() - (this.manualEditStartTime || 0);
    const OVERRIDE_THRESHOLD = 30000; // 30秒

    if (timeSinceEdit > OVERRIDE_THRESHOLD) {
      console.log('PostalCodeAutoFill: 手動編集から時間が経過したため自動上書きを許可');
      return true;
    }

    // 現在の住所が自動入力された住所と同じ場合は上書き許可
    const currentAddress = this.getCurrentAddress();
    if (currentAddress === this.lastAutoFilledAddress) {
      console.log('PostalCodeAutoFill: 住所が自動入力値と同じため上書きを許可');
      return true;
    }

    // 住所が空の場合は上書き許可
    if (!currentAddress || currentAddress.trim() === '') {
      return true;
    }

    // その他の場合は上書きを制御
    return false;
  }

  /**
   * 手動編集状態をリセット
   */
  resetManualEditState() {
    this.isManuallyEdited = false;
    this.manualEditStartTime = null;
    this.originalAddressValue = '';
    this.addressEditHistory = [];
    
    // 視覚的インジケーターを非表示
    this.hideManualEditIndicator();
  }

  /**
   * ユーザーの入力意図を保持して住所を更新
   * @param {Object} addressData - 新しい住所データ
   */
  updateAddressPreservingUserIntent(addressData) {
    if (!this.addressField || !addressData) return;

    const currentAddress = this.getCurrentAddress();
    const currentParts = this.parseAddressParts(currentAddress);
    
    // 新しい基本住所を構築
    const newBaseAddress = addressData.fullAddress || this.buildFullAddress(
      addressData.prefecture,
      addressData.city,
      addressData.town
    );

    // ユーザーが追加した詳細情報を保持
    let preservedDetails = '';
    
    if (this.isManuallyEdited && currentParts.details) {
      // 手動編集された詳細情報を保持
      preservedDetails = currentParts.details;
      console.log('PostalCodeAutoFill: ユーザーの詳細情報を保持:', preservedDetails);
    }

    // 新しい完全な住所を構築
    const newFullAddress = newBaseAddress + preservedDetails;

    // 住所フィールドを更新
    this.addressField.value = newFullAddress;
    this.lastAutoFilledAddress = newBaseAddress;

    // 詳細情報がある場合は手動編集状態を維持
    if (preservedDetails) {
      this.isManuallyEdited = true;
      this.showManualEditIndicator();
    } else {
      this.resetManualEditState();
    }

    // 視覚的フィードバック
    this.highlightAddressField();

    console.log('PostalCodeAutoFill: 入力意図を保持して住所更新完了:', newFullAddress);
  }

  /**
   * 住所の詳細部分のみを更新（基本住所は保持）
   * @param {string} newDetails - 新しい詳細情報
   */
  updateAddressDetails(newDetails) {
    if (!this.addressField) return;

    const baseAddress = this.lastAutoFilledAddress || '';
    const newFullAddress = baseAddress + (newDetails || '');

    this.addressField.value = newFullAddress;

    // 詳細情報がある場合は手動編集状態にする
    if (newDetails && newDetails.trim()) {
      this.isManuallyEdited = true;
      this.showManualEditIndicator();
    } else {
      this.resetManualEditState();
    }

    console.log('PostalCodeAutoFill: 住所詳細部分更新完了:', newFullAddress);
  }

  /**
   * 住所の基本部分のみを更新（詳細部分は保持）
   * @param {Object} addressData - 新しい基本住所データ
   */
  updateBaseAddressOnly(addressData) {
    if (!this.addressField || !addressData) return;

    const currentParts = this.parseAddressParts(this.getCurrentAddress());
    const newBaseAddress = addressData.fullAddress || this.buildFullAddress(
      addressData.prefecture,
      addressData.city,
      addressData.town
    );

    // 既存の詳細情報を保持
    const newFullAddress = newBaseAddress + (currentParts.details || '');

    this.addressField.value = newFullAddress;
    this.lastAutoFilledAddress = newBaseAddress;

    console.log('PostalCodeAutoFill: 基本住所のみ更新完了:', newFullAddress);
  }

  /**
   * 手動編集を確定
   */
  finalizeManualEdit() {
    if (this.isManuallyEdited) {
      const currentValue = this.getCurrentAddress();
      
      // 編集内容をログに記録
      console.log('PostalCodeAutoFill: 手動編集確定', {
        original: this.originalAddressValue,
        edited: currentValue,
        editDuration: Date.now() - (this.manualEditStartTime || 0)
      });

      // カスタムイベントを発火
      this.dispatchManualEditEvent(currentValue);
    }
  }

  /**
   * 手動編集状態の視覚的インジケーターを表示
   */
  showManualEditIndicator() {
    if (!this.addressField) return;

    // 住所フィールドに手動編集状態のスタイルを適用
    this.addressField.classList.add('postal-code-manually-edited');
    this.addressField.style.borderLeft = '3px solid #ffc107'; // 黄色の左ボーダー
    this.addressField.title = '手動で編集されています';
  }

  /**
   * 手動編集状態の視覚的インジケーターを非表示
   */
  hideManualEditIndicator() {
    if (!this.addressField) return;

    this.addressField.classList.remove('postal-code-manually-edited');
    this.addressField.style.borderLeft = '';
    this.addressField.title = '';
  }

  /**
   * 手動編集イベントを発火
   * @param {string} editedValue - 編集された住所値
   */
  dispatchManualEditEvent(editedValue) {
    try {
      const event = new CustomEvent('postalCodeAutoFill:manualEdit', {
        detail: {
          originalValue: this.originalAddressValue,
          editedValue: editedValue,
          editHistory: this.addressEditHistory,
          addressField: this.addressField
        },
        bubbles: true
      });

      this.addressField.dispatchEvent(event);
    } catch (error) {
      console.warn('PostalCodeAutoFill: 手動編集イベント発火エラー:', error);
    }
  }

  /**
   * 手動編集の状態を取得
   * @returns {Object} 手動編集状態の詳細情報
   */
  getManualEditState() {
    return {
      isManuallyEdited: this.isManuallyEdited,
      originalValue: this.originalAddressValue,
      currentValue: this.getCurrentAddress(),
      editStartTime: this.manualEditStartTime,
      editHistory: [...this.addressEditHistory], // コピーを返す
      lastAutoFilledAddress: this.lastAutoFilledAddress
    };
  }

  /**
   * 住所フィールドをクリア
   */
  clearAddressField() {
    if (this.addressField) {
      this.addressField.value = '';
      this.resetManualEditState();
    }
  }

  /**
   * キャッシュから住所データを取得
   * 有効期限をチェックして期限切れの場合は削除
   * @param {string} postalCode - 郵便番号
   * @returns {Object|null} キャッシュされた住所データまたはnull
   */
  getCachedAddress(postalCode) {
    if (!this.config.enableCache || !this.cache.has(postalCode)) {
      return null;
    }

    const cacheEntry = this.cache.get(postalCode);
    const now = Date.now();

    // 有効期限チェック
    if (now - cacheEntry.timestamp > this.cacheExpirationTime) {
      console.log('PostalCodeAutoFill: キャッシュ期限切れのため削除', { postalCode });
      this.cache.delete(postalCode);
      return null;
    }

    // アクセス時刻を更新（LRU管理用）
    cacheEntry.lastAccessed = now;
    this.cache.set(postalCode, cacheEntry);

    return cacheEntry.data;
  }

  /**
   * 住所データをキャッシュに保存
   * サイズ制限を超える場合は古いエントリを削除
   * @param {string} postalCode - 郵便番号
   * @param {Object} addressData - 住所データ
   */
  setCachedAddress(postalCode, addressData) {
    if (!this.config.enableCache) {
      return;
    }

    const now = Date.now();
    const cacheEntry = {
      data: addressData,
      timestamp: now,
      lastAccessed: now,
      postalCode: postalCode
    };

    // サイズ制限チェック
    if (this.cache.size >= this.maxCacheSize) {
      this.evictOldestCacheEntry();
    }

    this.cache.set(postalCode, cacheEntry);
    
    console.log('PostalCodeAutoFill: キャッシュに保存', { 
      postalCode, 
      cacheSize: this.cache.size,
      maxSize: this.maxCacheSize 
    });
  }

  /**
   * 最も古いキャッシュエントリを削除（LRU方式）
   */
  evictOldestCacheEntry() {
    let oldestKey = null;
    let oldestTime = Date.now();

    for (const [key, entry] of this.cache.entries()) {
      if (entry.lastAccessed < oldestTime) {
        oldestTime = entry.lastAccessed;
        oldestKey = key;
      }
    }

    if (oldestKey) {
      this.cache.delete(oldestKey);
      console.log('PostalCodeAutoFill: 古いキャッシュエントリを削除', { 
        evictedKey: oldestKey,
        newSize: this.cache.size 
      });
    }
  }

  /**
   * 期限切れキャッシュエントリをクリーンアップ
   */
  cleanupExpiredCache() {
    if (!this.config.enableCache) {
      return;
    }

    const now = Date.now();
    const expiredKeys = [];

    for (const [key, entry] of this.cache.entries()) {
      if (now - entry.timestamp > this.cacheExpirationTime) {
        expiredKeys.push(key);
      }
    }

    expiredKeys.forEach(key => this.cache.delete(key));

    if (expiredKeys.length > 0) {
      console.log('PostalCodeAutoFill: 期限切れキャッシュをクリーンアップ', {
        expiredCount: expiredKeys.length,
        remainingSize: this.cache.size
      });
    }
  }

  /**
   * キャッシュ統計情報を取得
   * @returns {Object} キャッシュ統計
   */
  getCacheStats() {
    const now = Date.now();
    let validEntries = 0;
    let expiredEntries = 0;

    for (const [key, entry] of this.cache.entries()) {
      if (now - entry.timestamp > this.cacheExpirationTime) {
        expiredEntries++;
      } else {
        validEntries++;
      }
    }

    return {
      totalEntries: this.cache.size,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      maxSize: this.maxCacheSize,
      expirationTime: this.cacheExpirationTime,
      hitRate: this.calculateCacheHitRate()
    };
  }

  /**
   * キャッシュヒット率を計算
   * @returns {number} ヒット率（0-1の範囲）
   */
  calculateCacheHitRate() {
    // 簡易的な実装（実際のヒット/ミス統計は別途管理が必要）
    const stats = this.getCacheStats();
    return stats.totalEntries > 0 ? stats.validEntries / stats.totalEntries : 0;
  }

  /**
   * キャッシュを完全にクリア
   */
  clearCache() {
    const previousSize = this.cache.size;
    this.cache.clear();
    
    console.log('PostalCodeAutoFill: キャッシュをクリア', { 
      clearedEntries: previousSize 
    });
  }

  /**
   * 定期的なキャッシュクリーンアップを開始
   */
  startCacheCleanup() {
    if (!this.config.enableCache) {
      return;
    }

    // 既存のタイマーがあればクリア
    this.stopCacheCleanup();

    // 定期クリーンアップタイマーを設定
    this.cacheCleanupTimer = setInterval(() => {
      this.cleanupExpiredCache();
    }, this.cacheCleanupInterval);

    console.log('PostalCodeAutoFill: キャッシュクリーンアップタイマー開始', {
      interval: this.cacheCleanupInterval
    });
  }

  /**
   * キャッシュクリーンアップタイマーを停止
   */
  stopCacheCleanup() {
    if (this.cacheCleanupTimer) {
      clearInterval(this.cacheCleanupTimer);
      this.cacheCleanupTimer = null;
      console.log('PostalCodeAutoFill: キャッシュクリーンアップタイマー停止');
    }
  }

  /**
   * API呼び出しが許可されているかチェック
   * レート制限に基づいて判定
   * @returns {boolean} API呼び出しが許可されているかどうか
   */
  isApiCallAllowed() {
    const now = Date.now();
    
    // 古い履歴を削除（時間窓外のもの）
    this.apiCallHistory = this.apiCallHistory.filter(
      timestamp => now - timestamp < this.apiCallWindow
    );

    // 制限内かどうかをチェック
    const isAllowed = this.apiCallHistory.length < this.maxApiCallsPerMinute;
    
    if (!isAllowed) {
      console.warn('PostalCodeAutoFill: API呼び出し制限に達しました', {
        callsInWindow: this.apiCallHistory.length,
        maxCalls: this.maxApiCallsPerMinute,
        windowMs: this.apiCallWindow
      });
    }

    return isAllowed;
  }

  /**
   * API呼び出し履歴を記録
   */
  recordApiCall() {
    const now = Date.now();
    this.apiCallHistory.push(now);
    
    // 履歴のサイズ制限（メモリ使用量制御）
    if (this.apiCallHistory.length > this.maxApiCallsPerMinute * 2) {
      this.apiCallHistory = this.apiCallHistory.slice(-this.maxApiCallsPerMinute);
    }

    console.log('PostalCodeAutoFill: API呼び出し記録', {
      totalCalls: this.apiCallHistory.length,
      timestamp: now
    });
  }

  /**
   * API呼び出し統計を取得
   * @returns {Object} API呼び出し統計情報
   */
  getApiCallStats() {
    const now = Date.now();
    const recentCalls = this.apiCallHistory.filter(
      timestamp => now - timestamp < this.apiCallWindow
    );

    return {
      recentCalls: recentCalls.length,
      maxCalls: this.maxApiCallsPerMinute,
      windowMs: this.apiCallWindow,
      remainingCalls: Math.max(0, this.maxApiCallsPerMinute - recentCalls.length),
      nextResetTime: recentCalls.length > 0 ? 
        Math.min(...recentCalls) + this.apiCallWindow : now
    };
  }

  /**
   * クリーンアップメソッド
   * イベントリスナーとUI要素を削除
   */
  destroy() {
    try {
      // タイマーをクリア
      this.clearDebounceTimer();
      this.stopCacheCleanup();

      // イベントリスナーを削除
      if (this.postalCodeField && this.handlePostalCodeInputBound) {
        this.postalCodeField.removeEventListener('input', this.handlePostalCodeInputBound);
        this.postalCodeField.removeEventListener('focus', this.hideErrorBound);
      }

      if (this.addressField) {
        if (this.handleAddressManualEditBound) {
          this.addressField.removeEventListener('input', this.handleAddressManualEditBound);
        }
        if (this.handleAddressFocusBound) {
          this.addressField.removeEventListener('focus', this.handleAddressFocusBound);
        }
        if (this.handleAddressBlurBound) {
          this.addressField.removeEventListener('blur', this.handleAddressBlurBound);
        }
      }

      // UI要素を削除
      this.removeUIElements();

      // 手動編集状態をリセット
      this.resetManualEditState();

      // 参照をクリア
      this.postalCodeField = null;
      this.addressField = null;
      this.cache.clear();
      this.apiCallHistory = [];

      // バインドされたハンドラーをクリア
      this.handlePostalCodeInputBound = null;
      this.handleAddressManualEditBound = null;
      this.handleAddressFocusBound = null;
      this.handleAddressBlurBound = null;
      this.hideErrorBound = null;

      console.log('PostalCodeAutoFill: クリーンアップ完了');
    } catch (error) {
      console.error('PostalCodeAutoFill: クリーンアップエラー:', error);
    }
  }
}

export default PostalCodeAutoFill;