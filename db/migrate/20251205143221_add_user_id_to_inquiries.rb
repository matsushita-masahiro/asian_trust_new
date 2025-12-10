class AddUserIdToInquiries < ActiveRecord::Migration[8.0]
  def change
    add_reference :inquiries, :user, null: true, foreign_key: true
  end
end
