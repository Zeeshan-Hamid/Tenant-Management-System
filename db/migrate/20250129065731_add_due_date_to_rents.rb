class AddDueDateToRents < ActiveRecord::Migration[7.2]
  def change
    add_column :rents, :due_date, :date
  end
end
