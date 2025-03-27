ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    section "Recent Rents" do
      table_for Rent.order("created_at desc").limit(10) do
        column :tenant
        column :unit
        column :amount
        column :payment_date
        column :status
      end
      strong { link_to "View All Rents", admin_rents_path }
    end
  end
end
