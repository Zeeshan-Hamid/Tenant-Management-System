class AddAmountPaidToRents < ActiveRecord::Migration[7.2]
  def change
    add_column :rents, :amount_paid, :integer, default: nil
  end
end
