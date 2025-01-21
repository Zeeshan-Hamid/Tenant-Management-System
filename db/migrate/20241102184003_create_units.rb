class CreateUnits < ActiveRecord::Migration[7.2]
  def change
    create_table :units do |t|
      t.references :property, null: false, foreign_key: true
      t.string :unit_number
      t.string :floor
      t.integer :square_footage
      t.decimal :rental_rate
      t.decimal :selling_rate
      t.string :status

      t.timestamps
    end
  end
end
