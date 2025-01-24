ActiveAdmin.register Unit do
  belongs_to :property
  navigation_menu :property

  permit_params :property_id, :unit_number, :floor, :selling_rate, :status

  filter :property
  filter :status, as: :select, collection: Unit.statuses.keys.map { |s| [s.titleize, s] }
  filter :floor
  filter :selling_rate

  index do
    selectable_column
    column :property
    column :unit_number
    column :floor
    column :selling_rate
    column :status do |unit|
      status_tag unit.status.titleize, 
                 class: unit.available_for_rent? ? :green : (unit.sold? ? :red : :orange)
    end
    actions
  end

  form do |f|
    f.inputs 'Unit Details' do
      f.input :property, as: :select, collection: Property.all
      f.input :unit_number
      f.input :floor
      f.input :selling_rate
      f.input :status, 
              as: :select, 
              collection: Unit.statuses.keys.map { |s| [s.titleize, s] },
              include_blank: false
    end
    f.actions
  end

  show do
    attributes_table do
      row :property
      row :unit_number
      row :floor
      row :selling_rate
      row :status do |unit|
        if unit.status.present?
          status_tag unit.status.titleize, 
                     class: unit.available_for_rent? ? :green : (unit.sold? ? :red : :orange)
        else
          status_tag "No Status", class: :gray
        end
      end
    end

    tabs do
      tab "Active Tenant" do
        panel "Tenant Details" do
          if unit.active_tenant.present?
            attributes_table_for unit.active_tenant do
              row :name
              row :phone
              row :email
              row :active
            end

            if unit.active_tenant.lease_agreement.present?
              panel "Lease Agreement" do
                attributes_table_for unit.active_tenant.lease_agreement do
                  row :start_date
                  row :end_date
                  row :rent_amount
                  row :security_deposit
                  row :annual_increment
                  row :increment_frequency
                  row :increment_type
                end
              end
            else
              div class: 'blank_slate' do
                span "No lease agreement found"
              end
            end

            div class: 'action_items' do
              link_to "Deactivate Tenant", 
                      deactivate_tenant_admin_property_unit_path(unit.property, unit), 
                      method: :put, 
                      data: { confirm: "Are you sure?" }, 
                      class: 'button'
            end
          else
            div class: 'blank_slate' do
              span "No active tenant"
            end
            div class: 'action_items' do
              link_to "Add Tenant", new_admin_unit_tenant_path(unit), class: 'button'
            end
          end
        end

        panel "Rent Payments" do
          if unit.active_tenant.present?
            rents = unit.active_tenant.rents.order(payment_date: :desc)
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
              div class: 'blank_slate' do
                span "No rent payments found"
              end
            end
          end
        end
      end

      # Add a new tab for Scheduled Rents
      tab "Scheduled Rents" do
        if unit.active_tenant.present?
          scheduled_rents = unit.active_tenant.rents.where("due_date >= ?", Date.today).order(due_date: :asc)
          if scheduled_rents.any?
            panel "Scheduled Rents" do
              table_for scheduled_rents do
                column :amount
                column :due_date
                column :status
              end
            end
          else
            div class: 'blank_slate' do
              span "No scheduled rents found."
            end
          end
        else
          div class: 'blank_slate' do
            span "No active tenant to display scheduled rents."
          end
        end
      end

      tab "Tenant History" do
        if unit.tenants.any?
          unit.tenants.where(active: false).each do |tenant|
            panel "Former Tenant: #{tenant.name}" do
              attributes_table_for tenant do
                row :name
                row :phone
                row :email
                row :move_in_date
                row :move_out_date
              end
            end
          end
        else
          div class: 'blank_slate' do
            span "No tenant history"
          end
        end
      end
    end
  end

  controller do
    def new
      @unit = Unit.new
      @unit.property_id = params[:property_id] if params[:property_id].present?
      super
    end
  end

  member_action :deactivate_tenant, method: :put do
    unit = Unit.find(params[:id])
    if tenant = unit.active_tenant
      tenant.update(active: false)
      redirect_to admin_property_unit_path(unit.property, unit), notice: "Tenant deactivated"
    else
      redirect_to admin_property_unit_path(unit.property, unit), alert: "No active tenant found"
    end
  end

  member_action :generate_rent, method: :post do
    unit = Unit.find(params[:id])
    result = unit.generate_rent
    flash[result[:success] ? :notice : :alert] = result[:message]
    redirect_to admin_property_unit_path(unit.property, unit)
  end
end