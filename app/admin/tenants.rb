
ActiveAdmin.register Tenant do
  belongs_to :unit
  permit_params :name, :unit_id, :active, :phone, :email, lease_agreement_attributes: [
    :rent_amount, :start_date, :end_date, :security_deposit, :increment_type, :annual_increment, :unit_id
  ]

  filter :name

  form do |f|
    f.inputs "Tenant Details" do
      f.input :name
      f.input :phone
      f.input :email

      f.inputs "Lease Agreement", for: [:lease_agreement, f.object.lease_agreement || LeaseAgreement.new] do |lease_form|
        lease_form.input :rent_amount
        lease_form.input :start_date, as: :datepicker
        lease_form.input :end_date, as: :datepicker
        lease_form.input :security_deposit
        lease_form.input :increment_type, as: :select, collection: ['fixed', 'percentage']
        lease_form.input :annual_increment
        lease_form.input :unit_id, as: :hidden, input_html: { value: params[:unit_id] }
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
