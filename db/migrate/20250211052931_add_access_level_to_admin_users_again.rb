class AddAccessLevelToAdminUsersAgain < ActiveRecord::Migration[7.2]
  def change
    # Only add the column if it doesn't exist
    unless column_exists?(:admin_users, :access_level)
      add_column :admin_users, :access_level, :integer, default: 3, null: false
    end
  end
end
