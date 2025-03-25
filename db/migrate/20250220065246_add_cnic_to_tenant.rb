class AddCnicToTenant < ActiveRecord::Migration[7.2]
  def change
    add_column :tenants, :cnic, :string unless column_exists?(:tenants, :cnic)
  end
end
