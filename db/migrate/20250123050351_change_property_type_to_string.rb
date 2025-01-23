class ChangePropertyTypeToString < ActiveRecord::Migration[7.2]
  def change
    change_column :properties, :property_type, :string
  end
end
