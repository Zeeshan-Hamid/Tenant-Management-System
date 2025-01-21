class AddAdvanceCreditToTenants < ActiveRecord::Migration[7.2]
  def change
    add_column :tenants, :advance_credit, :decimal, precision: 10, scale: 2, default: 0.0, null: false
  end
end
