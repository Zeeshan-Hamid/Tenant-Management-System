class CreateUserProperties < ActiveRecord::Migration[7.2]
  def change
    create_table :user_properties do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_properties, [ :user_id, :property_id ], unique: true
  end
end
