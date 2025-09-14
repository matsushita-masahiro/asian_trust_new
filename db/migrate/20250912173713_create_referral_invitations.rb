class CreateReferralInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :referral_invitations do |t|
      t.references :referrer, null: false, foreign_key: { to_table: :users }
      t.string :referral_token, null: false
      t.references :target_level, null: false, foreign_key: { to_table: :levels }
      t.string :passcode, null: false
      t.datetime :expires_at
      t.datetime :used_at
      t.references :invited_user, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    
    add_index :referral_invitations, :referral_token, unique: true
    add_index :referral_invitations, [:referral_token, :passcode]
  end
end
