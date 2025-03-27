# frozen_string_literal: true

ActiveAdmin.register PublicActivity::Activity do
  permit_params :trackable_type, :trackable_id, :owner_type, :owner_id, :key, :parameters,
                :recipient_type, :recipient_id

  menu label: "Activity Log", priority: 1
  actions :index, :show

  batch_action :destroy, confirm: "Are you sure you want to delete these activity logs?" do |ids|
    PublicActivity::Activity.where(id: ids).destroy_all
    redirect_to collection_path, notice: "Selected activity logs have been deleted."
  end

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
      if activity.trackable.present?
        case activity.trackable_type
        when "AdminUser" then activity.trackable.email
        when "User", "Tenant" then activity.trackable.name.presence || activity.trackable.phone_number.presence || "#{activity.trackable_type} ##{activity.trackable.id}"
        when "Property" then activity.trackable.name
        when "Unit", "Rent" then activity.trackable.respond_to?(:name) ? activity.trackable.name : "#{activity.trackable_type} ##{activity.trackable.id}"
        else activity.trackable.to_s
        end
      elsif activity.trackable_type == "Property"
        activity.parameters["property_name"] || "Deleted Property"
      else
        "Deleted or not found"
      end
    end
  end

  index do
    selectable_column
    id_column

    column("Trackable") { |activity| controller.display_trackable(activity) }
    column("Action") { |activity| controller.humanized_action(activity.key) }
    column("Performed By", sortable: :owner_id) do |activity|
      activity.owner.try(:email) || activity.owner.try(:name) || "System"
    end
    column("Created At", :created_at)
    actions
  end

  show do
    attributes_table do
      row("Trackable") { |activity| controller.display_trackable(activity) }
      row("Action") { |activity| controller.humanized_action(activity.key) }
      row("Performed By") do |activity|
        activity.owner.try(:email) || activity.owner.try(:name) || "System"
      end
      row :created_at
      row :parameters
    end
  end
end
