# Implementation Plan

- [x] 1. データベース設計とマイグレーション
  - Addressesテーブルの作成
  - 必要なインデックスの設定
  - 外部キー制約の追加
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 1.1 Addressマイグレーションファイル作成
  - user_id, address_type, postal_code, address, timestamps, deleted_atカラムを含むテーブル作成
  - ユニークインデックス(user_id, address_type)の設定
  - _Requirements: 1.1, 1.2_

- [x] 1.2 インデックス最適化
  - user_id, address_type, deleted_atに適切なインデックスを設定
  - パフォーマンス向上のための複合インデックス作成
  - _Requirements: 1.1_

- [x] 2. Addressモデルの実装
  - 基本的なモデル構造とバリデーション
  - 住所タイプのenum定義
  - 郵便番号フォーマット機能
  - _Requirements: 1.1, 1.2, 1.5, 2.1, 2.2_

- [x] 2.1 Addressモデル基本機能実装
  - belongs_to :user関連の設定
  - address_type enumの定義（registration, shipping）
  - 基本バリデーション（presence, uniqueness）
  - _Requirements: 1.1, 1.2, 1.5, 2.1_

- [x] 2.2 郵便番号フォーマット機能実装
  - before_saveコールバックで郵便番号を自動フォーマット
  - バリデーションで正しい形式をチェック
  - _Requirements: 5.1_

- [x] 2.3 住所タイプ管理機能実装
  - address_type_labelsクラスメソッド実装
  - address_type_labelインスタンスメソッド実装
  - 将来の拡張を考慮した設計
  - _Requirements: 6.1, 6.3, 6.5_

- [x] 3. Userモデル拡張
  - Address関連の追加
  - 便利メソッドの実装
  - 後方互換性メソッド
  - _Requirements: 1.3, 1.4, 2.3, 4.1, 4.2_

- [x] 3.1 User-Address関連設定
  - has_many :addresses関連の追加
  - has_one :registration_address, :shipping_address関連の追加
  - dependent: :destroyの設定
  - _Requirements: 1.3, 1.4, 2.3_

- [x] 3.2 後方互換性メソッド実装
  - primary_addressメソッドの実装
  - 既存のinvoice_base.addressとの互換性維持
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4. AddressesController実装
  - CRUD操作の実装
  - Ajax対応
  - 権限制御
  - _Requirements: 2.1, 2.2, 5.2_

- [x] 4.1 基本CRUD操作実装
  - create, update, destroyアクションの実装
  - 適切なパラメータ制御
  - エラーハンドリング
  - _Requirements: 2.1, 2.2_

- [x] 4.2 Ajax対応とJSON レスポンス
  - JSON形式でのレスポンス対応
  - フロントエンドとの連携
  - _Requirements: 2.1_

- [x] 4.3 権限制御実装
  - ユーザーは自分の住所のみ操作可能
  - 管理者権限の実装
  - _Requirements: 5.2_

- [x] 5. users/showページUI実装
  - 住所情報表示セクション追加
  - インライン編集フォーム
  - Ajax による非同期更新
  - _Requirements: 2.3, 3.1, 3.2_

- [x] 5.1 住所表示セクション実装
  - 登録住所・配送先住所の表示エリア作成
  - 住所未登録時の表示対応
  - 編集ボタンの配置
  - _Requirements: 2.3, 3.1_

- [x] 5.2 住所編集フォーム実装
  - インライン編集フォームの作成
  - 郵便番号・住所入力フィールド
  - バリデーションエラー表示
  - _Requirements: 3.2, 5.1_

- [x] 5.3 Ajax非同期更新機能
  - JavaScript/Stimulusでの非同期処理
  - フォーム送信とレスポンス処理
  - 成功・エラー時のUI更新
  - _Requirements: 2.1_

- [x] 6. 管理者画面での住所管理機能
  - admin/users/showでの住所表示
  - 管理者による住所編集機能
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 6.1 admin/users/showページ更新
  - 住所情報表示の追加
  - 登録住所・配送先住所の表示
  - _Requirements: 3.1, 3.2_

- [x] 6.2 管理者用住所編集機能
  - 管理者による住所編集フォーム
  - 権限チェックの実装
  - _Requirements: 3.2, 5.2_

- [x] 7. データマイグレーション
  - 既存invoice_baseデータの移行
  - 後方互換性の確保
  - _Requirements: 4.2, 4.3_

- [x] 7.1 既存データ移行スクリプト作成
  - invoice_baseからAddressへのデータ移行
  - 登録住所タイプでの移行
  - データ整合性チェック
  - _Requirements: 4.2_

- [x] 7.2 移行後の動作確認
  - 既存機能での住所表示確認
  - 後方互換性メソッドの動作確認
  - _Requirements: 4.3, 4.4_

- [x] 8. テスト実装
  - モデルテスト
  - コントローラーテスト
  - 統合テスト
  - _Requirements: All_

- [x] 8.1 Addressモデルテスト
  - バリデーションテスト
  - 関連テスト
  - 郵便番号フォーマットテスト
  - _Requirements: 1.1, 1.2, 1.5, 2.1, 5.1_

- [x] 8.2 Userモデル拡張テスト
  - Address関連のテスト
  - 後方互換性メソッドテスト
  - _Requirements: 1.3, 1.4, 2.3, 4.1_

- [x] 8.3 AddressesControllerテスト
  - CRUD操作テスト
  - 権限制御テスト
  - Ajax レスポンステスト
  - _Requirements: 2.1, 2.2, 5.2_

- [x] 8.4 統合テスト
  - 住所登録フローテスト
  - 管理画面での住所管理テスト
  - データ移行テスト
  - _Requirements: All_