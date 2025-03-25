class RemoveUnitIdFromTenants < ActiveRecord::Migration[7.2]
  def change
    remove_column :tenants, :unit_id, :bigint
  end
end
