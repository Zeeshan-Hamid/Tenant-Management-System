class AddReceiptImageToTenants < ActiveRecord::Migration[7.2]
  def change
    add_column :tenants, :receipt_image, :string, array: true, default: []
  end
end
