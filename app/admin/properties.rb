ActiveAdmin.register Property do
  permit_params :name, :description, :property_type, :address, :city, :state, :country, :zip_code,
                :active

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
          link_to "+ Unit", new_admin_unit_path(property_id: property.id), class: "button"
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
                link_to("View", admin_unit_path(unit), class: "member_link"),
                link_to("Edit", edit_admin_unit_path(unit), class: "member_link"),
                link_to("Delete", admin_unit_path(unit), method: :delete,
                                                          data: { confirm: "Are you sure?" }, class: "member_link")
              ]
              safe_join(links, " | ")
            end
          end
        end
      end

      tab "Available for Sale" do
        panel "Units Available for Sale" do
          table_for property.units.where(status: :available_for_selling) do
            column :unit_number
            column :floor
            column :selling_rate
            column :status
            column "Actions" do |unit|
              link_to "View", admin_unit_path(unit)
            end
          end
        end
      end
    end

    panel "Activity Log for this Property" do
      # collect related activity IDs
      lease_ids  = property.lease_agreements.pluck(:id)
      unit_ids   = property.units.pluck(:id)
      rent_ids   = Rent.where(lease_agreement_id: lease_ids).pluck(:id)
      tenant_ids = property.lease_agreements.pluck(:tenant_id)

      activities = PublicActivity::Activity.where(
        "(trackable_type = ? AND trackable_id IN (?)) OR \
         (trackable_type = ? AND trackable_id IN (?)) OR \
         (trackable_type = ? AND trackable_id IN (?)) OR \
         (trackable_type = ? AND trackable_id IN (?)) OR \
         (trackable_type = ? AND trackable_id = ?)",
        "LeaseAgreement", lease_ids,
        "Rent",            rent_ids,
        "Tenant",          tenant_ids,
        "Unit",            unit_ids,
        "Property",        property.id
      ).order(created_at: :desc)

      table_for activities do
        column("Trackable")  { |act| controller.display_trackable(act) }
        column("Action")      { |act| controller.humanized_action(act.key) }
        column("Performed By") { |act| act.owner.try(:email) || act.owner.try(:name) || "System" }
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Property Details" do
      f.input :name, required: true
      f.input :description
      property_types = Property.property_types.keys
      render partial: "admin/properties/property_type_selector",
             locals: { f: f, property: f.object, property_types: property_types }
      f.input :address, required: true
      f.input :city, required: true
      f.input :state
      f.input :country, as: :select, collection: ISO3166::Country.all.sort_by(&:common_name).map { |c|
        [ c.common_name, c.common_name ]
      }, include_blank: "Select Country", required: true
      f.input :zip_code, hint: "Use 12345 or 12345-6789 format",
                         input_html: { pattern: '\d{5}(-\d{4})?' }
      f.input :active
    end
    f.actions
  end

  after_save(&:update_units_count)

  controller do
    def humanized_action(key)
      model, action = key.to_s.split(".", 2)
      action_text = case action
      when "create" then "has been created"
      when "update" then "has been updated"
      when "destroy" then "has been deleted"
      else action.humanize.downcase
      end
      "#{model.humanize} #{action_text}"
    end

    def display_trackable(activity)
      return "Deleted or not found" unless activity.trackable.present?

      case activity.trackable_type
      when "LeaseAgreement" then "Lease Agreement ##{activity.trackable.id}"
      when "Rent"           then "Rent ##{activity.trackable.id}"
      when "Tenant"         then activity.trackable.name
      when "Unit"           then "Unit #{activity.trackable.unit_number}"
      when "Property"       then activity.trackable.name
      else activity.trackable.to_s
      end
    end

    def destroy
      property = Property.find(params[:id])
      if property.destroy
        redirect_to admin_properties_path, notice: "Property was successfully deleted."
      else
        redirect_to admin_property_path(property),
alert: property.errors.full_messages.to_sentence.presence || "Property could not be deleted since its units are on rent."
      end
    end
  end
end
