class AddIsAdvanceToRents < ActiveRecord::Migration[7.2]
  def change
    add_column :rents, :is_advance, :boolean
  end
end
