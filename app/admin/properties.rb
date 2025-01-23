# app/admin/properties.rb
ActiveAdmin.register Property do
  permit_params :name, :description, :property_type, :address, 
                :city, :state, :country, :zip_code, :active

  filter :name
  filter :address
  filter :property_type
  filter :city
  filter :country

  index do
    selectable_column
    column :name
    column :property_type
    column :city
    column :country
    column :units_count
    column :active
    actions
  end

  show do
    attributes_table do
      row :name
      row :address
      row :property_type
      row :description
      row :city
      row :state
      row :country
      row :zip_code
      row :units_count
      row :active
      row :created_at
      row :updated_at
    end

    tabs do
      tab "Rentals" do 
        div do
          link_to '+ Unit', new_admin_property_unit_path(property), class: 'button'
        end
        panel "Rental Units" do
          table_for property.units do
            column "Unit Number", &:unit_number
            column "Floor", &:floor
            column "Tenant Name" do |unit|
              unit.active_tenant&.name || "-"
            end
            column "Selling Rate", &:selling_rate
            column "Availability", &:status
            column "Actions" do |unit|
              links = [
                link_to('View', admin_property_unit_path(property, unit), class: 'member_link'),
                link_to('Edit', edit_admin_property_unit_path(property, unit), class: 'member_link'),
                link_to('Delete', admin_property_unit_path(property, unit), 
                        method: :delete, 
                        data: { confirm: 'Are you sure?' }, 
                        class: 'member_link')
              ]
              safe_join(links, ' | ')
            end
          end
        end
      end

      tab "Available for Sale" do  
        panel "Units Available for Sale" do
          table_for property.units.where(status: 'available') do
            column :unit_number
            column :floor
            column :selling_rate
            column :status
            column "Actions" do |unit|
              link_to 'View', admin_property_unit_path(property, unit)
            end
          end
        end
      end
    end
  end

  form do |f|
    f.inputs "Property Details" do
      f.input :name, required: true
      f.input :description
      f.input :property_type, 
              as: :select, 
              collection: Property.property_types.keys.map { |k| [k.titleize, k] },
              include_blank: false
      f.input :address, required: true
      f.input :city, required: true
      f.input :state
      f.input :country, 
              as: :select,
              collection: ISO3166::Country.all.sort_by(&:common_name).map { |c| 
                [c.common_name, c.common_name] 
              },
              include_blank: 'Select Country',
              required: true
      f.input :zip_code, 
              hint: 'Use 12345 or 12345-6789 format',
              input_html: { pattern: '\d{5}(-\d{4})?' }
      f.input :active
    end
    f.actions
  end

  # Update units count after save
  after_save do |property|
    property.update_units_count
  end
end