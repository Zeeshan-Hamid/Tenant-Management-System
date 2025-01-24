# app/admin/rent.rb
ActiveAdmin.register Rent do
  permit_params :tenant_id, :unit_id, :amount, :due_date, :payment_date, :status, :month
  menu label: "Rent List"

  # Custom action to mark rent as paid
  member_action :mark_as_paid, method: :put do
    rent = Rent.find(params[:id])
    rent.update!(status: 'paid', payment_date: Date.today)
    redirect_to admin_rents_path, notice: "Rent marked as paid!"
  end

  form do |f|
    f.inputs "Rent Details" do
      f.input :tenant, as: :select, collection: Tenant.all
      f.input :unit, as: :select, collection: Unit.all
      
      f.input :due_date, as: :datepicker
      f.input :payment_date, as: :datepicker
      f.input :month, as: :datepicker
      f.input :status, as: :select, collection: Rent.statuses.keys.map { |s| [s.titleize, s] }
    end
    f.actions
  end

  # Index view
  index do
    selectable_column
    column :tenant
    column :unit
   
    column :due_date
    column :payment_date
    column :status do |rent|
      status_tag rent.status
    end
    actions defaults: true do |rent|
      link_to "Mark as Paid", mark_as_paid_admin_rent_path(rent), method: :put
    end
  end

  # Show view
  show do
    attributes_table do
      row :tenant
      row :unit
      row :amount
      row :due_date
      row :payment_date
      row :status
    end

    # Add a "Mark as Paid" button to the show page
    panel "Actions" do
      link_to "Mark as Paid", mark_as_paid_admin_rent_path(rent), method: :put, class: 'button'
    end
  end
end