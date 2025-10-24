# ユーザー住所管理機能 要件定義

## Introduction

ユーザーが複数の住所（登録住所と配送先住所）を管理できる機能を実装する。既存のusersテーブルに直接住所カラムを追加するのではなく、独立したAddressモデルを作成して柔軟な住所管理を実現する。

## Glossary

- **User**: システムのユーザー（既存のUserモデル）
- **Address**: ユーザーの住所情報を管理するモデル
- **Address_Type**: 住所の種類（登録住所、配送先住所、その他将来追加される住所タイプ）
- **Registration_Address**: 登録住所（billing_address）
- **Shipping_Address**: 配送先住所（shipping_address）
- **Extensible_Address_Types**: 将来的に追加可能な住所タイプ（会社住所、緊急連絡先住所など）

## Requirements

### Requirement 1

**User Story:** ユーザーとして、登録住所と配送先住所を別々に管理したい。そうすることで、請求先と配送先を分けて管理できる。

#### Acceptance Criteria

1. THE Address_Model SHALL store user_id, address_type, postal_code, address, created_at, updated_at
2. THE Address_Model SHALL support address_type enum with initial values 'registration' and 'shipping' and allow future extension
3. THE User_Model SHALL have association with Address_Model through has_many relationship
4. THE Address_Model SHALL belong_to User_Model
5. THE Address_Model SHALL validate presence of user_id, address_type, and address

### Requirement 2

**User Story:** ユーザーとして、各住所タイプ（登録住所、配送先住所）につき1つずつの住所を登録したい。そうすることで、重複した住所タイプを避けることができる。

#### Acceptance Criteria

1. THE Address_Model SHALL validate uniqueness of address_type scoped to user_id
2. WHEN user creates address with existing address_type, THE System SHALL update existing address
3. THE User_Model SHALL provide convenience methods for accessing registration_address and shipping_address
4. THE Address_Model SHALL provide display methods for formatted address output

### Requirement 3

**User Story:** 管理者として、ユーザーの住所情報を管理画面で確認・編集したい。そうすることで、ユーザーサポートや配送管理を効率的に行える。

#### Acceptance Criteria

1. THE Admin_Interface SHALL display user's registration_address and shipping_address
2. THE Admin_Interface SHALL allow editing of user addresses
3. THE Admin_Interface SHALL show address history and timestamps
4. THE System SHALL maintain backward compatibility with existing invoice_base address display

### Requirement 4

**User Story:** システムとして、既存の住所表示機能との互換性を保ちたい。そうすることで、既存の機能を壊すことなく新機能を導入できる。

#### Acceptance Criteria

1. THE User_Model SHALL provide backward compatible methods for existing address access
2. THE System SHALL migrate existing invoice_base addresses to new Address model
3. THE System SHALL maintain existing address display in user profiles
4. THE Address_Model SHALL provide fallback methods when addresses are not set

### Requirement 5

**User Story:** ユーザーとして、住所情報を安全に管理したい。そうすることで、個人情報が適切に保護される。

#### Acceptance Criteria

1. THE Address_Model SHALL validate postal_code format when present
2. THE Address_Model SHALL sanitize address input to prevent XSS
3. THE System SHALL log address changes for audit purposes
4. THE Address_Model SHALL soft delete addresses instead of hard delete
#
## Requirement 6

**User Story:** システム管理者として、将来的に新しい住所タイプを追加したい。そうすることで、ビジネス要件の変化に柔軟に対応できる。

#### Acceptance Criteria

1. THE Address_Model SHALL use string-based enum for address_type to allow easy extension
2. THE System SHALL provide migration-friendly approach for adding new address_types
3. THE Address_Model SHALL validate address_type against allowed values
4. THE System SHALL maintain backward compatibility when new address_types are added
5. THE Admin_Interface SHALL dynamically display all available address_types