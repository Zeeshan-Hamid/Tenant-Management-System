# frozen_string_literal: true

ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation, :access_level

  index do
    selectable_column
    id_column
    column :email

    column "Access Level" do |admin|
      case admin.access_level
      when "administrator"
        status_tag "Administrator", class: "status-administrator"
      when "property_manager"
        status_tag "Properties Manager", class: "status-property-manager"
      when "unit_manager"
        status_tag "Units Manager", class: "status-unit-manager"
      else
        status_tag admin.access_level.humanize
      end
    end

    column :created_at
    actions defaults: false do |admin|
      links = [ link_to("View", admin_admin_user_path(admin)) ]
      links << link_to("Edit", edit_admin_admin_user_path(admin)) unless admin.administrator?
      if current_admin_user.administrator? && admin != current_admin_user && !admin.administrator?
        links << link_to("Delete", admin_admin_user_path(admin),
                           method: :delete,
                           data: { confirm: "Are you sure you want to delete this admin user?" })
      end
      safe_join(links, " | ")
    end
  end

  show do
    attributes_table do
      row :email
      row("Access Level") { |admin| admin.access_level.humanize }
      row :created_at
      row :updated_at
    end
  end

  filter :email
  filter :created_at

  form do |f|
    if f.object.persisted? && f.object.administrator?
      para "Super Admin details cannot be edited."
    else
      f.inputs "Admin Details" do
        f.input :email
        f.input :password
        f.input :password_confirmation

        f.input :access_level,
                as: :radio,
                collection: [
                  [
                    "<span class='tooltip-wrapper'>Administrator
                      <span class='tooltip'>Super Admin with access to all features</span>
                    </span>".html_safe,
                    AdminUser.access_levels[:administrator]
                  ],
                  [
                    "<span class='tooltip-wrapper'>Property Manager
                      <span class='tooltip'>Can manage Properties and Users</span>
                    </span>".html_safe,
                    AdminUser.access_levels[:property_manager]
                  ],
                  [
                    "<span class='tooltip-wrapper'>Unit Manager
                      <span class='tooltip'>Can manage Units and Lease agreements</span>
                    </span>".html_safe,
                    AdminUser.access_levels[:unit_manager]
                  ]
                ],
                include_blank: false,
                label: "Access Level"
      end

      f.inputs "Confirmation" do
        f.input :admin_password_confirmation, label: "Confirm your password", as: :password
      end

      f.actions
    end
  end

  controller do
    before_action :check_administrator, only: %i[new create]

    def check_administrator
      return if current_admin_user.administrator?

      flash[:error] = I18n.t("admin_user.errors.administrator_only")
      redirect_to admin_admin_users_path
    end

    def verify_password_confirmation(redirect_path, required: false)
      confirmation = params[:admin_user].delete(:admin_password_confirmation)
      if (required || confirmation.present?) && !current_admin_user.valid_password?(confirmation)
        flash[:error] = I18n.t("admin_user.errors.password_confirmation")
        redirect_to redirect_path and return false
      end
      true
    end

    def edit
      if resource.administrator?
        flash[:error] = I18n.t("admin_user.errors.administrator_edit")
        redirect_to admin_admin_user_path(resource) and return
      else
        super
      end
    end

    def update
      if resource.administrator?
        flash[:error] = I18n.t("admin_user.errors.administrator_edit")
        redirect_to admin_admin_user_path(resource) and return
      else
        return unless verify_password_confirmation(edit_admin_admin_user_path(resource))
        super
      end
    end

    def create
      unless current_admin_user.administrator?
        flash[:error] = I18n.t("admin_user.errors.administrator_only")
        redirect_to admin_admin_users_path and return
      end

      return unless verify_password_confirmation(new_admin_admin_user_path, required: true)

      if params[:admin_user][:access_level].to_s =~ /\A\d+\z/
        params[:admin_user][:access_level] =
          AdminUser.access_levels.invert[params[:admin_user][:access_level].to_i]
      end

      super
    end
  end
end