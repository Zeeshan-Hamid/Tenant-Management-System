ActiveAdmin.register Unit do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :property_id, :unit_number, :floor, :square_footage, :rental_rate, :selling_rate, :status
  #
  # or
  #
  # permit_params do
  #   permitted = [:property_id, :unit_number, :floor, :square_footage, :rental_rate, :selling_rate, :status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  belongs_to :property
  navigation_menu :property

  filter :properties

  permit_params :unit_number, :floor, :selling_rate, :status, :property_id # Ensure property_id is permitted
  

  form do |f|
    f.inputs do
      f.input :property, as: :select, collection: Property.all # This allows selection of properties
      f.input :unit_number
      f.input :floor
      f.input :selling_rate
      f.input :status
    end
    f.actions
  end

  controller do
    def new
      @unit = Unit.new
      @unit.property_id = params[:property_id] if params[:property_id].present?
      super
    end
  end



  member_action :deactivate_tenant, method: :put do
    property = Property.find(params[:property_id])
    unit = property.units.find(params[:id])

    tenant = unit.active_tenant
    tenant.deactivate # Use the method to deactivate the tenant
    redirect_to admin_property_unit_path(property, unit), notice: "Tenant has been deactivated."
  end

  member_action :generate_rent, method: :post do
    property = Property.find(params[:property_id])
    unit = property.units.find(params[:id])
    result = unit.generate_rent

    flash[result[:success] ? :notice : :alert] = result[:message]
    redirect_to admin_property_unit_path(property, unit)
  end

  show do
    attributes_table do
      row :property
      row :unit_number
      row :floor
      row :active  
    end
    tabs do
      tab "Active Tenant" do
  
        panel "Tenant" do

          if unit.tenants.any?(&:active)
            active_tenant = unit.active_tenant
            div do
              h3 "Active Tenant: #{active_tenant.name}"
            end
  
            attributes_table_for active_tenant do
              row :name
              row :phone
              row :email
              row :active
              # Add any other tenant attributes you want to display...
            end

            if active_tenant.lease_agreement
              attributes_table_for active_tenant.lease_agreement do
                row :start_date
                row :end_date
                row :rent_amount
                row :security_deposit
                row :annual_increment
                row :increment_frequency
                row :increment_type
                # Add any other lease agreement attributes you want to display...
              end

            else
              div "No lease agreement found for this tenant."
            end

            div do
              link_to "Deactivate Tenant", deactivate_tenant_admin_property_unit_path(unit.property, unit), method: :put, data: { confirm: "Are you sure you want to deactivate this tenant?" }, class: 'button'
            end

          else
            div do
              h3 "No Active Tenant"
            end
            div do
              link_to "Add Tenant", new_admin_unit_tenant_path(unit), class: 'button'
            end
          end
        end

        panel "Rents" do
          if unit.active_tenant
            rents = unit.active_tenant.rents
            if rents.any?
              table_for rents do
                column :amount
                column :payment_date
                column :payment_method
                column :payment_status
                column :balance
                column :advance_credit
              end
            else
              div "No rent payments found for this tenant."
              
              # unless unit.active_tenant.rents.where(month: Date.today.beginning_of_month).exists?
              #   link_to "Generate Rent for #{rent_due_date.strftime('%B %Y')}", generate_rent_admin_property_unit_path(unit.property, unit), method: :post, class: 'button'
 
              # end
            end
          end
        end
      end

      tab "History" do
        if unit.tenants.any?
          unit.tenants.where(active: false).each do |tenant|
            panel "Lease Agreement: #{tenant.name}" do
              
              attributes_table_for tenant do
                row :name
                row :phone
                row :email
                row :active
                # Add any other tenant attributes you want to display...
              end
              
                
              
            end
          end
        else
          div "No tenants associated with this unit."
        end
      end
    end
  end
  
end
