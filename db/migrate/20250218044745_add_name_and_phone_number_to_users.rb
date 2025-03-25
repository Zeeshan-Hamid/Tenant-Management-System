class AddNameAndPhoneNumberToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :phone_number, :string, null: false, default: ""
    add_index :users, :phone_number, unique: true
  end
end
