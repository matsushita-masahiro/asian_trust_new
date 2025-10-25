# カート住所選択機能 要件定義

## Introduction

カート画面でユーザーが登録住所と配送先住所をラジオボタンで選択できる機能を実装する。ユーザーは注文前に配送先住所を明確に選択でき、選択した住所が注文処理に反映される。

## Glossary

- **Cart_System**: カート機能を管理するシステム
- **Address_Selection**: ユーザーがカート画面で行う住所選択操作
- **Registration_Address**: ユーザーの登録住所（既存のuser.registration_address）
- **Shipping_Address**: ユーザーの配送先住所（既存のuser.shipping_address）
- **Selected_Address**: ユーザーがカート画面で選択した配送先住所
- **Address_Radio_Button**: 住所選択用のラジオボタンUI要素
- **Delivery_Address_Display**: カート画面での配送先住所表示エリア

## Requirements

### Requirement 1

**User Story:** ユーザーとして、カート画面で登録住所と配送先住所をラジオボタンで選択したい。そうすることで、注文前に配送先を明確に指定できる。

#### Acceptance Criteria

1. WHEN user has both registration_address and shipping_address, THE Cart_System SHALL display both addresses with Address_Radio_Button
2. THE Cart_System SHALL show address details including postal_code and full address for each option
3. THE Cart_System SHALL allow user to select one address using Address_Radio_Button
4. THE Cart_System SHALL highlight selected address visually
5. THE Cart_System SHALL remember user's address selection during cart session

### Requirement 2

**User Story:** ユーザーとして、住所が1つしか登録されていない場合は自動的にその住所が選択されていてほしい。そうすることで、余計な操作なく注文を進められる。

#### Acceptance Criteria

1. WHEN user has only registration_address, THE Cart_System SHALL automatically select registration_address
2. WHEN user has only shipping_address, THE Cart_System SHALL automatically select shipping_address
3. THE Cart_System SHALL display single address without radio button when only one address exists
4. THE Cart_System SHALL show clear indication that address is automatically selected

### Requirement 3

**User Story:** ユーザーとして、住所が未登録の場合は適切な案内メッセージを見たい。そうすることで、住所登録が必要であることを理解し、適切なページに移動できる。

#### Acceptance Criteria

1. WHEN user has no addresses registered, THE Cart_System SHALL display address registration prompt
2. THE Cart_System SHALL provide link to user profile page for address registration
3. THE Cart_System SHALL prevent order progression when no address is available
4. THE Cart_System SHALL show clear error message about missing address

### Requirement 4

**User Story:** ユーザーとして、選択した住所が注文処理に正しく反映されてほしい。そうすることで、意図した配送先に商品が届く。

#### Acceptance Criteria

1. WHEN user selects address and proceeds to order, THE Cart_System SHALL pass Selected_Address to order processing
2. THE Cart_System SHALL validate Selected_Address before order submission
3. THE Cart_System SHALL maintain address selection consistency throughout order flow
4. THE Cart_System SHALL update order confirmation with Selected_Address details

### Requirement 5

**User Story:** システムとして、住所選択の状態をJavaScriptで管理したい。そうすることで、ユーザーの選択に応じてリアルタイムでUIを更新できる。

#### Acceptance Criteria

1. THE Cart_System SHALL provide JavaScript function for address selection handling
2. WHEN user changes address selection, THE Cart_System SHALL update UI immediately
3. THE Cart_System SHALL validate address selection on client side
4. THE Cart_System SHALL provide feedback for address selection changes

### Requirement 6

**User Story:** ユーザーとして、WOTT商品とその他商品の両方がカートにある場合も住所選択ができてほしい。そうすることで、商品の種類に関係なく配送先を指定できる。

#### Acceptance Criteria

1. WHEN cart contains WOTT products and other products, THE Cart_System SHALL display Address_Selection for other products section
2. THE Cart_System SHALL maintain separate address display for WOTT products if needed
3. THE Cart_System SHALL apply Selected_Address to appropriate product categories
4. THE Cart_System SHALL show clear indication of which products use selected address