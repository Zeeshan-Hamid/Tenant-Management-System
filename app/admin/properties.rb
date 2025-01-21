ActiveAdmin.register Property do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :name, :description, :property_type, :address, :city, :state, :country, :zip_code, :active
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :description, :property_type, :address, :city, :state, :country, :zip_code, :active]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :name
  filter :address
  filter :property_type

  show do
    attributes_table do
      row :name
      row :address
      row :property_type
      row :description
      row :units_count # Displays the count of units
      # Add other property attributes you want to display...
    end

    tabs do
      tab "Rentals" do 
        div do
          link_to '+ Unit', new_admin_property_unit_path(property), class: 'button'
        end
        panel "Rental" do
          table_for property.units do
            column "Unit Number" do |unit|
              unit.unit_number
            end
            column "Floor" do |unit|
              unit.floor
            end

            column "Tenant Name" do |unit|
              active_tenant = unit.active_tenant # Use the defined method
              active_tenant ? active_tenant.name : "-" # Display tenant name or a message if no active tenant is assigned
            end
            column "Selling Rate" do |unit|
              unit.selling_rate
            end
            column "Availability" do |unit|
              unit.status
            end
            column "Actions" do |unit|
              links = []
              links << link_to('view', admin_property_unit_path(property, unit), class: 'member_link')
              links << link_to('Edit', edit_admin_property_unit_path(property, unit), class: 'member_link')
              links << link_to('Delete', admin_property_unit_path(property, unit), method: :delete, data: { confirm: 'Are you sure?' }, class: 'member_link')
              safe_join(links)
            end
            # Add other unit attributes as needed...
          end
        end
      end  
      tab "Available for Sales" do  
        # Panel for Units Specifically Available for Sale
        panel "Units Available for Sale" do
          table_for property.units do
            column :unit_number
            column :floor
            column :selling_rate
            column :status
            # actions do |unit|
            #   links << link_to('Edit', edit_admin_property_unit_path(property, unit), class: 'member_link')
            #   links << link_to('Delete', admin_property_unit_path(property, unit), method: :delete, data: { confirm: 'Are you sure?' }, class: 'member_link')
            # end
          end
        end
      end  
    end
  end

  # Form for creating or editing a property
  form do |f|
    f.inputs "Property Details" do
      f.input :name
      f.input :description
      f.input :property_type, as: :select, collection: Property.property_types.keys
      f.input :address
      f.input :city
      f.input :state
      f.input :country, as: :select,
  collection: ISO3166::Country.all.sort_by(&:common_name).map { |c| 
    [c.common_name, c.common_name] 
  },
  include_blank: 'Select Country'
      f.input :zip_code
      f.input :active
    end
    f.actions
  end
  
  
end
