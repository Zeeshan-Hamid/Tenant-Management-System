class AddPaymentMethodToRents < ActiveRecord::Migration[7.2]
  def change
    add_column :rents, :payment_method, :string
  end
end
