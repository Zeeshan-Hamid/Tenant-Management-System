class CreateProperties < ActiveRecord::Migration[7.2]
  def change
    create_table :properties do |t|
      t.string :name
      t.text :description
      t.string :property_type
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.string :zip_code
      t.boolean :active
      t.timestamps
    end
  end
end
