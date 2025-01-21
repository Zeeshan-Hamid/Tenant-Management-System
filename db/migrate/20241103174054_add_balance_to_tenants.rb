class AddBalanceToTenants < ActiveRecord::Migration[7.2]
  def change
    add_column :tenants, :balance, :decimal, :default => 0
    #Ex:- :default =>''
  end
end
