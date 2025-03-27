# frozen_string_literal: true

ActiveAdmin.register Unit do
  menu label: "Units", priority: 3

  filter :property
  filter :unit_number
  filter :status

  permit_params :unit_number, :floor, :rental_rate, :selling_rate, :status, :property_id

  form do |f|
    f.inputs do
      f.input :property, as: :select, collection: Property.all
      f.input :unit_number
      f.input :floor
      f.input :status,
              as: :select,
              collection: Unit.statuses.map { |key, value| [ key.humanize, value ] },
              include_blank: false
      f.input :rental_rate,
              as: :number,
              input_html: {
                id: "rental_rate_field",
                min: 0,
                step: 100,
                value: f.object.rental_rate || 0,
                style: "display: none;"
              }
      f.input :selling_rate,
              as: :number,
              input_html: {
                id: "selling_rate_field",
                min: 0,
                step: 1000,
                value: f.object.selling_rate || 0,
                style: "display: none;"
              }
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :unit_number
    column :floor
    column :property
    column :status do |unit|
      unit.status.humanize
    end
    column :rental_rate
    actions
  end

  show do
    attributes_table do
      row :property
      row :unit_number
      row :floor
      row :status do |unit|
        unit.status.humanize
      end
      row :rental_rate
    end

    panel "Lease Agreements" do
      table_for resource.lease_agreements do
        column :id
        column :start_date
        column :end_date
        column :status
        column("Tenant") { |lease| lease.tenant.name }
        column("Actions") do |lease|
          link_to "View", admin_lease_agreement_path(lease)
        end
      end
    end
  end

  action_item :add_lease_agreement, only: :show, if: proc {
    resource.lease_agreements.where(status: "Active").empty?
  } do
    link_to "Add New Lease Agreement", new_admin_lease_agreement_path(
      property_id: resource.property_id,
      "lease_agreement[unit_ids][]" => resource.id
    ), class: "button"
  end

  controller do
    def new
      @unit = Unit.new
      @unit.property_id = params[:property_id] if params[:property_id].present?
      super
    end

    def create
      params[:unit][:status] = params[:unit][:status].to_i
      super
    end

    def update
      params[:unit][:status] = params[:unit][:status].to_i
      super
    end

    def destroy
      @unit = Unit.find_by(id: params[:id])
      unless @unit
        flash[:alert] = "Unit not found."
        return redirect_to admin_units_path
      end

      if @unit.destroy
        flash[:notice] = "Unit deleted successfully."
        redirect_to admin_units_path
      else
        flash[:alert] = @unit.errors.full_messages.to_sentence
        redirect_to admin_unit_path(@unit)
      end
    end
  end

  member_action :generate_rent, method: :post do
    property = Property.find(params[:property_id])
    unit = property.units.find(params[:id])
    result = unit.generate_rent(unit_params[:month])
    flash[result[:success] ? :notice : :alert] = result[:message]
    redirect_to admin_property_unit_path(property, unit)
  end
end
