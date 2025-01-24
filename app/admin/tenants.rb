
ActiveAdmin.register Tenant do
  belongs_to :unit
  permit_params :name, :unit_id, :active, :phone, :email, lease_agreement_attributes: [
    :id, :unit_id, :start_date, :end_date, :rent_amount,
    :security_deposit, :annual_increment, :increment_frequency, :increment_type
  ]

  filter :name

  form do |f|
    f.inputs "Tenant Details" do
      f.input :unit
      f.input :name
      f.input :phone
      f.input :email
      f.input :active
    end

    f.inputs "Lease Agreement" do
      f.has_many :lease_agreement, new_record: true do |la|
        la.input :start_date, as: :datepicker
        la.input :end_date, as: :datepicker
        
        la.input :security_deposit
        la.input :annual_increment
        la.input :increment_frequency, as: :select, collection: %w[yearly quarterly]
        la.input :increment_type, as: :select, collection: %w[fixed percentage]
      end
    end

    f.actions
  
  end

  controller do
    def create
      @unit = Unit.find(params[:unit_id])
      @tenant = @unit.tenants.new(tenant_params)

      if @tenant.save
        @tenant.activate
        redirect_to admin_property_unit_path(@unit.property, @unit), notice: "Tenant added successfully."
      else
        render :new
      end
    end

    private

    def tenant_params
      params.require(:tenant).permit(
        :name, :phone, :email, lease_agreement_attributes: [
          :rent_amount, :start_date, :end_date, :security_deposit, :increment_type, :annual_increment, :unit_id
        ]
      )
    end
  end
end

# app/admin/tenant.rb
ActiveAdmin.register Tenant do
  permit_params :name, :phone, :email, :unit_id, :active,
                lease_agreement_attributes: [
                  :id, :unit_id, :start_date, :end_date, :rent_amount,
                  :security_deposit, :annual_increment, :increment_frequency, :increment_type
                ]

  form do |f|
    f.inputs "Tenant Details" do
      f.input :unit
      f.input :name
      f.input :phone
      f.input :email
      f.input :active
    end

    f.inputs "Lease Agreement" do
      f.has_many :lease_agreement, new_record: true do |la|
        la.input :start_date, as: :datepicker
        la.input :end_date, as: :datepicker
        la.input :rent_amount
        la.input :security_deposit
        la.input :annual_increment
        la.input :increment_frequency, as: :select, collection: %w[yearly quarterly]
        la.input :increment_type, as: :select, collection: %w[fixed percentage]
      end
    end

    f.actions
  end
end
