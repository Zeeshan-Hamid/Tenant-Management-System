class ChangeStatusToIntegerInUnits < ActiveRecord::Migration[7.2]
  def up
    change_column :units, :status, 'integer USING CAST(status AS integer)'
  end

  def down
    change_column :units, :status, :string
  end
end
