class AddRentNameToRents < ActiveRecord::Migration[7.2]
  def change
    add_column :rents, :rent_name, :string
  end
end
