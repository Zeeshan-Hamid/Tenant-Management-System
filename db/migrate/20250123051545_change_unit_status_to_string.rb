class ChangeUnitStatusToString < ActiveRecord::Migration[7.2]
  def change
    change_column :units, :status, :string
  end
end
