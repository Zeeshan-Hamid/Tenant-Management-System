# frozen_string_literal: true

ActiveAdmin.register User do
  permit_params :name, :phone_number, user_properties_attributes: [ :id, :property_id, :_destroy, { lease_agreement_ids: [] } ]

  controller do
    include UserManagementConcern

    before_action :authenticate_admin_user!
    before_action :set_user, only: %i[edit update destroy]
    before_action :load_properties, only: %i[new create edit update]

    def new
      @user = User.new
      prepare_form_data
      render :new
    end

    def create
      @user = User.new(permitted_params[:user])

      if save_user_with_properties
        redirect_to_user_path_with_notice("User successfully created.")
      else
        prepare_form_data
        render :new
      end
    end

    def update
      process_user_properties_params if params[:user] && params[:user][:user_properties_attributes]

      if @user.update!(permitted_params[:user])
        filter_user_properties!
        remove_deactivated_lease_agreements!
        redirect_to_user_path_with_notice("User successfully updated.")
      else
        prepare_form_data
        render :edit
      end
    end

    def edit
      prepare_form_data
      render :edit
    end

    def destroy
      message = @user.destroy ? "User successfully deleted." : "There was an issue deleting the user."
      redirect_to admin_users_path, notice: message
    end
    
    private
    
    # Remove any user_properties that have no associated lease agreements
    def filter_user_properties!
      @user.user_properties.each do |user_property|
        if user_property.lease_agreements.empty?
          user_property.destroy
        end
      end
    end
    
    # Remove associations to deactivated lease agreements
    def remove_deactivated_lease_agreements!
      @user.user_properties.each do |user_property|
        # Find deactivated lease agreements for this user property
        deactivated_lease_ids = user_property.lease_agreements.deactivated_agreements.pluck(:id)
        
        # Remove these associations
        if deactivated_lease_ids.any?
          UserLeaseAgreement.where(
            user_property_id: user_property.id,
            lease_agreement_id: deactivated_lease_ids
          ).destroy_all
        end
        
        # If no active lease agreements remain for this property, remove the property
        if user_property.lease_agreements.active_agreements.empty?
          user_property.destroy
        end
      end
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :phone_number
    column "Assigned Properties" do |user|
      user.properties.pluck(:name).join(", ")
    end
    column :created_at
    actions
  end

  filter :name
  filter :phone_number
  filter :properties, as: :check_boxes, collection: proc { Property.pluck(:name, :id) }

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "User Details" do
      f.input :name
      f.input :phone_number, label: "Mobile Number"
    end

    f.inputs "Assign Lease Agreements" do
      properties = controller.instance_variable_get(:@properties)
      available_lease_agreements = controller.instance_variable_get(:@available_lease_agreements)

      if properties.any? && available_lease_agreements.any?
        render partial: "admin/users/property_lease_selector",
               locals: {
                 user: f.object,
                 properties: properties,
                 available_lease_agreements: available_lease_agreements
               }
      else
        div class: "blank-slate" do
          span class: "blank-slate-heading" do
            "No Properties Available"
          end
          span class: "blank-slate-text" do
            "There are no properties with unassigned lease agreements available."
          end
        end
      end
    end

    panel "Assigned Properties and Lease Agreements" do
      table_for f.object.user_properties do |up|
        column "Property" do |up|
          up.property.name
        end
        column "Lease Agreements" do |up|
          assigned_las = up.lease_agreements.active
          if assigned_las.any?
            ul do
              assigned_las.each do |la|
                unit_names = la.units.map(&:unit_number).join(", ")
                li link_to(
                  "Lease Agreement ##{la.id} (#{la.status}) - Units: #{unit_names}",
                  admin_lease_agreement_path(la)
                )
              end
            end
          else
            "No lease agreements assigned"
          end
        end
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :phone_number
      row :created_at
      row :updated_at
    end

    panel "Assigned Properties and Lease Agreements" do
      table_for user.user_properties do |up|
        column "Property" do |up|
          up.property.name
        end
        column "Lease Agreements" do |up|
          assigned_las = up.lease_agreements.active
          if assigned_las.any?
            ul do
              assigned_las.each do |la|
                unit_names = la.units.map(&:unit_number).join(", ")
                li link_to(
                  "Lease Agreement ##{la.id} (#{la.status}) - Units: #{unit_names}",
                  admin_lease_agreement_path(la)
                )
              end
            end
          else
            "No lease agreements assigned"
          end
        end
      end
    end
  end
end
