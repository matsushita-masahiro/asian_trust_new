# WOTT Level Management System Implementation Plan

## Phase 1: Database Structure Setup

- [x] 1. Create WottLevels table and model
  - Create migration for wott_levels table with name, value, timestamps
  - Add unique indexes for name and value columns
  - Create WottLevel model with basic validations
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Add WOTT level association to Users
  - Create migration to add wott_level_id to users table
  - Add foreign key constraint to wott_levels table
  - Update User model with belongs_to :wott_level association
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [x] 3. Extend ProductPrices for WOTT level support
  - Create migration to add wott_level_id to product_prices table
  - Add foreign key constraint and validation logic
  - Update ProductPrice model to handle both level types
  - _Requirements: 2.3, 3.3_

## Phase 2: Model Integration and Methods

- [ ] 4. Implement WottLevel model functionality
  - Add symbol method for level identification
  - Add scope for ordered level display
  - Add has_many association to users
  - _Requirements: 3.1, 3.2, 5.1_

- [x] 5. Add WOTT level helper methods to User model
  - Implement wott_level_name method
  - Implement has_wott_level? checker method
  - Implement wott_level_symbol method
  - Add display methods for UI integration
  - _Requirements: 3.3, 3.4, 5.2, 5.3, 5.4_

- [x] 6. Update Product model for WOTT price handling
  - Extend price_for method to handle WOTT levels
  - Add WOTT-specific price calculation methods
  - Maintain backward compatibility with existing methods
  - _Requirements: 3.5, 5.5_

## Phase 3: Data Seeding and Migration

- [x] 7. Create WOTT level seed data
  - Add WOTT level data to fixtures or seeds
  - Include all 7 levels with correct value hierarchy
  - Ensure consistent naming with existing system
  - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [x] 8. Set up WOTT product pricing structure
  - Create ProductPrice records for WOTT products
  - Define pricing for each WOTT level
  - Link WOTT Device to appropriate price levels
  - _Requirements: 4.4, 4.5_

- [ ]* 9. Write comprehensive tests
  - Create unit tests for WottLevel model validations
  - Test User-WottLevel associations and methods
  - Test ProductPrice-WottLevel integration
  - Add integration tests for dual-level scenarios
  - _Requirements: All requirements validation_

## Phase 4: System Integration

- [ ] 10. Update purchase system for WOTT levels
  - Modify purchase creation to use WOTT levels for WOTT products
  - Update seller_price calculation for WOTT products
  - Ensure proper level detection in purchase flow
  - _Requirements: 2.2, 3.4_

- [ ] 11. Update admin interface for dual levels
  - Display both levels in user management
  - Allow editing of WOTT levels in admin panel
  - Show appropriate level in purchase management
  - _Requirements: 5.1, 5.2, 5.4_

- [ ]* 12. Add data validation and error handling
  - Implement proper error messages for invalid levels
  - Add data integrity checks during migrations
  - Handle edge cases for users with missing levels
  - _Requirements: 4.5, 5.3_