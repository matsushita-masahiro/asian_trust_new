require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    # テストデータを直接作成
    @level = Level.find_or_create_by!(value: 1) { |l| l.name = "テストレベル" }
    @user = User.create!(
      name: "テストユーザー#{rand(1000)}",
      email: "test#{rand(1000)}@example.com",
      password: "password",
      confirmed_at: Time.current,
      level_id: @level.id
    )
  end

  def teardown
    # テストデータをクリーンアップ（外部キー制約を考慮した順序）
    Address.destroy_all
    InvoiceBase.destroy_all
    User.destroy_all
    # Levelは他のテストでも使用される可能性があるので削除しない
  end

  # Address関連のテスト
  test "should have many addresses" do
    assert_respond_to @user, :addresses
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @user.addresses
  end

  test "should have one registration_address" do
    assert_respond_to @user, :registration_address
    registration_address = @user.registration_address
    if registration_address
      assert_equal 'registration', registration_address.address_type
    end
  end

  test "should have one shipping_address" do
    assert_respond_to @user, :shipping_address
    shipping_address = @user.shipping_address
    if shipping_address
      assert_equal 'shipping', shipping_address.address_type
    end
  end

  test "should return correct registration_address" do
    # 登録住所を作成
    registration_address = Address.create!(
      user: @user,
      address_type: 'registration',
      address: '東京都渋谷区渋谷1-1-1',
      postal_code: '123-4567'
    )
    
    @user.reload
    assert_equal registration_address, @user.registration_address
    assert_equal 'registration', @user.registration_address.address_type
  end

  test "should return correct shipping_address" do
    # 配送先住所を作成
    shipping_address = Address.create!(
      user: @user,
      address_type: 'shipping',
      address: '東京都新宿区新宿2-2-2',
      postal_code: '987-6543'
    )
    
    @user.reload
    assert_equal shipping_address, @user.shipping_address
    assert_equal 'shipping', @user.shipping_address.address_type
  end

  test "should destroy addresses when user is destroyed" do
    # 住所を作成
    Address.create!(
      user: @user,
      address_type: 'registration',
      address: '削除テスト住所'
    )
    
    address_ids = @user.addresses.pluck(:id)
    assert address_ids.any?, "住所が作成されていません"
    
    @user.destroy
    
    address_ids.each do |address_id|
      assert_nil Address.find_by(id: address_id), "住所が削除されていません"
    end
  end

  # 後方互換性メソッドテスト
  test "should return primary_address from registration_address when available" do
    # 登録住所を作成
    Address.create!(
      user: @user,
      address_type: 'registration',
      address: '登録住所テスト'
    )
    
    @user.reload
    registration_address = @user.registration_address
    expected_address = registration_address&.address
    assert_equal expected_address, @user.primary_address
  end

  test "should return primary_address from invoice_base when registration_address is not available" do
    # invoice_baseを作成
    InvoiceBase.create!(
      user: @user,
      address: 'invoice_base住所テスト',
      email: 'invoice@example.com'
    )
    
    @user.reload
    # 登録住所がない場合、invoice_baseから取得
    assert_equal 'invoice_base住所テスト', @user.primary_address
  end

  test "should return nil for primary_address when no addresses available" do
    # 住所が何もない状態
    assert_nil @user.primary_address
  end

  test "should allow multiple address types per user" do
    # 登録住所と配送先住所の両方を作成
    registration = Address.create!(
      user: @user,
      address_type: 'registration',
      address: '登録住所テスト'
    )
    
    shipping = Address.create!(
      user: @user,
      address_type: 'shipping', 
      address: '配送先住所テスト'
    )
    
    @user.reload
    assert_equal 2, @user.addresses.count
    assert_equal registration, @user.registration_address
    assert_equal shipping, @user.shipping_address
  end

  test "should not allow duplicate address types per user" do
    # 最初の登録住所を作成
    Address.create!(
      user: @user,
      address_type: 'registration',
      address: '最初の登録住所'
    )
    
    # 同じタイプの住所を作成しようとする
    duplicate_registration = Address.new(
      user: @user,
      address_type: 'registration',
      address: '重複する登録住所'
    )
    
    assert_not duplicate_registration.valid?
    assert_includes duplicate_registration.errors[:address_type], "はすでに存在します"
  end
end