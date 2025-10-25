# WOTT Level Management System Requirements

## Introduction

WOTT商品の販売に対する独立したレベル管理システムを構築します。既存の上清液販売用のlevelsテーブルとは別に、WOTT専用のレベル体系を管理し、ユーザーが両方のレベルを持てるようにします。

## Glossary

- **WOTT_Level_System**: WOTT商品販売専用のレベル管理システム
- **Stem_Cell_Level_System**: 既存の上清液販売用レベル管理システム（levelsテーブル）
- **Dual_Level_User**: 上清液レベルとWOTTレベルの両方を持つユーザー
- **WOTT_Levels_Table**: WOTT販売レベルを管理する新しいテーブル
- **User_WOTT_Level_Association**: ユーザーとWOTTレベルの関連付け

## Requirements

### Requirement 1

**User Story:** As a system administrator, I want to create a separate level system for WOTT products, so that WOTT sales can have different level structures from stem cell products.

#### Acceptance Criteria

1. THE WOTT_Level_System SHALL create a new wott_levels table with the same structure as the existing levels table
2. THE WOTT_Level_System SHALL support the following levels: 総代理店, 代理店, サポーター, お客様, サロン, クリニック
3. THE WOTT_Level_System SHALL exclude アドバイザー level from the WOTT level hierarchy
4. THE WOTT_Level_System SHALL assign unique IDs and value rankings to each WOTT level
5. THE WOTT_Level_System SHALL maintain level hierarchy through value-based ordering

### Requirement 2

**User Story:** As a user, I want to have both stem cell and WOTT sales levels, so that I can participate in both product categories with appropriate permissions.

#### Acceptance Criteria

1. THE User_WOTT_Level_Association SHALL add a wott_level_id column to the users table
2. THE User_WOTT_Level_Association SHALL allow users to have different levels for stem cell and WOTT products
3. THE User_WOTT_Level_Association SHALL maintain referential integrity between users and wott_levels tables
4. THE User_WOTT_Level_Association SHALL allow null values for users who don't participate in WOTT sales
5. THE User_WOTT_Level_Association SHALL preserve existing stem cell level associations

### Requirement 3

**User Story:** As a developer, I want proper model associations and methods, so that I can easily access WOTT level information for users.

#### Acceptance Criteria

1. THE Dual_Level_User SHALL provide a belongs_to association to wott_level in the User model
2. THE Dual_Level_User SHALL provide a has_many association from WottLevel to users
3. THE Dual_Level_User SHALL include helper methods to check WOTT level permissions
4. THE Dual_Level_User SHALL provide methods to get WOTT level name and value
5. THE Dual_Level_User SHALL maintain backward compatibility with existing stem cell level methods

### Requirement 4

**User Story:** As a system administrator, I want to seed initial WOTT level data, so that the system has the correct level hierarchy from the start.

#### Acceptance Criteria

1. THE WOTT_Level_System SHALL create seed data for all 6 WOTT levels
2. THE WOTT_Level_System SHALL assign appropriate value rankings (0=highest, 5=lowest)
3. THE WOTT_Level_System SHALL use consistent naming with the existing level system
4. THE WOTT_Level_System SHALL provide migration scripts to create the table structure
5. THE WOTT_Level_System SHALL ensure data integrity during the migration process

### Requirement 5

**User Story:** As a user interface developer, I want to distinguish between stem cell and WOTT levels, so that I can display the correct level information in different contexts.

#### Acceptance Criteria

1. THE Dual_Level_User SHALL provide clear method names to differentiate between level types
2. THE Dual_Level_User SHALL support displaying both levels simultaneously when needed
3. THE Dual_Level_User SHALL handle cases where users have only one type of level
4. THE Dual_Level_User SHALL provide consistent formatting for level display
5. THE Dual_Level_User SHALL maintain existing UI compatibility for stem cell levels