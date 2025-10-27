/**
 * CustomDropdown - カスタムドロップダウン機能
 */
class CustomDropdown {
  constructor() {
    this.dropdownHandlers = {};
  }

  init() {
    const dropdownToggle = document.getElementById('mypageDropdown');
    const dropdownMenu = document.getElementById('mypageDropdownMenu');

    console.log("🔍 Dropdown elements check:", {
      toggle: dropdownToggle,
      menu: dropdownMenu,
      toggleExists: !!dropdownToggle,
      menuExists: !!dropdownMenu
    });

    if (!dropdownToggle || !dropdownMenu) {
      console.log("❌ Dropdown elements not found");
      return false;
    }

    // 既存のイベントリスナーを削除
    this.cleanup();

    // ドロップダウントグルクリック
    this.dropdownHandlers.toggle = (e) => {
      console.log("🖱️ Dropdown toggle clicked");
      e.preventDefault();
      e.stopPropagation();

      const isOpen = dropdownMenu.classList.contains('show');
      console.log("📋 Dropdown state:", { isOpen, classList: dropdownMenu.classList.toString() });

      if (isOpen) {
        dropdownMenu.classList.remove('show');
        console.log("🔒 Dropdown closed");
      } else {
        dropdownMenu.classList.add('show');
        console.log("🔓 Dropdown opened");
      }
    };

    // ドキュメントクリック（外部クリックで閉じる）
    this.dropdownHandlers.document = (e) => {
      if (!dropdownToggle.contains(e.target) && !dropdownMenu.contains(e.target)) {
        dropdownMenu.classList.remove('show');
      }
    };

    // ESCキーで閉じる
    this.dropdownHandlers.keydown = (e) => {
      if (e.key === 'Escape') {
        dropdownMenu.classList.remove('show');
      }
    };

    // イベントリスナーを追加
    dropdownToggle.addEventListener('click', this.dropdownHandlers.toggle);
    document.addEventListener('click', this.dropdownHandlers.document);
    document.addEventListener('keydown', this.dropdownHandlers.keydown);

    console.log("✅ Custom dropdown initialized");
    return true;
  }

  cleanup() {
    const dropdownToggle = document.getElementById('mypageDropdown');
    
    if (dropdownToggle && this.dropdownHandlers.toggle) {
      dropdownToggle.removeEventListener('click', this.dropdownHandlers.toggle);
    }
    if (this.dropdownHandlers.document) {
      document.removeEventListener('click', this.dropdownHandlers.document);
    }
    if (this.dropdownHandlers.keydown) {
      document.removeEventListener('keydown', this.dropdownHandlers.keydown);
    }
  }
}

export default CustomDropdown;