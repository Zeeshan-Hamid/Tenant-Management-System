class CreateRents < ActiveRecord::Migration[7.2]
  def change
    create_table :rents do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.decimal :amount
      t.date :payment_date
      t.string :status

      t.timestamps
    end
  end
end
