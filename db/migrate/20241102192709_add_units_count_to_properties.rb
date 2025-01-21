class AddUnitsCountToProperties < ActiveRecord::Migration[7.2]
  def change
    add_column :properties, :units_count, :integer
  end
end
