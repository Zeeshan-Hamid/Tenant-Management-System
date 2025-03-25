class CreateTenants < ActiveRecord::Migration[7.2]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.boolean :active
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end
    add_index :tenants, [ :unit_id, :active ], unique: true, where: "active", name: "unique_active_tenant_per_unit"
  end
end
