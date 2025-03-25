class ChangePropertyTypeToIntegerInProperties < ActiveRecord::Migration[7.2]
  def up
    add_column :properties, :property_type_temp, :integer


    Property.reset_column_information
    Property.find_each do |property|
      if property.property_type.present?

        property.update_column(:property_type_temp, Property.property_types[property.property_type])
      end
    end


    remove_column :properties, :property_type
    rename_column :properties, :property_type_temp, :property_type
  end

  def down
    add_column :properties, :property_type_str, :string

    Property.reset_column_information
    Property.find_each do |property|
      if property.property_type.present?
        property.update_column(:property_type_str, Property.property_types.key(property.property_type))
      end
    end

    remove_column :properties, :property_type
    rename_column :properties, :property_type_str, :property_type
  end
end
