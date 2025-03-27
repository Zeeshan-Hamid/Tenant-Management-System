# frozen_string_literal: true

ActiveAdmin.register Rent do
  permit_params :lease_agreement_id, :amount, :payment_date, :status, :due_date, :pending_amount, :rent_name, :amount_paid

  scope :all, default: true
  scope :pending
  scope :paid
  scope :overdue

  member_action :mark_as_paid, method: :put do
    rent = Rent.find_by(id: params[:id])
    redirect_to admin_rents_path, alert: "Rent record not found." and return unless rent

    if rent.update(status: "paid", payment_date: Time.current)
      if SmsService.send_payment_confirmation(rent.lease_agreement.tenant.phone, rent.amount)
        redirect_to admin_rents_path, notice: "Rent marked as paid and SMS sent successfully"
      else
        redirect_to admin_rents_path, notice: "Rent marked as paid but SMS failed to send"
      end
    else
      redirect_to admin_rents_path, alert: "Failed to mark rent as paid"
    end
  end

  filter :lease_agreement_id, label: "Lease Agreement", as: :select, collection: proc {
    LeaseAgreement.where.not(status: "Deactivated").map do |la|
      [ "##{la.id} - Tenant: #{la.tenant.name}", la.id ]
    end
  }
  filter :amount
  filter :payment_date
  filter :status

  index do
    selectable_column
    column "Tenant" do |rent|
      rent.lease_agreement.tenant
    end
    column "Lease Agreement", &:lease_agreement
    column :amount do |rent|
      "PKR #{rent.amount}"
    end
    column :amount_paid
    column "Amount Pending" do |rent|
      pending = rent.amount_paid.to_f.positive? ? (rent.amount - rent.amount_paid) : rent.amount
      "PKR #{pending}"
    end
    

    column :payment_date
    column :due_date
    column :status
    column "Actions" do |rent|
      if rent.status != "paid"
        link_to "Mark as Paid",
                mark_as_paid_admin_rent_path(rent),
                method: :put,
                class: "button",
                data: { confirm: "Are you sure?" }
      end
    end
    actions
  end

  show do
    attributes_table do
      row :rent_name
      row "Tenant" do |rent|
        rent.lease_agreement.tenant
      end
      row "Lease Agreement", &:lease_agreement
      row :amount do |rent|
        "PKR #{rent.amount}"
      end
      row :amount_paid
      column "Amount Pending" do |rent|
        pending = rent.amount_paid.to_f.positive? ? (rent.amount - rent.amount_paid) : rent.amount
        "PKR #{pending}"
      end      

      row :rent_name
      row :payment_date
      row :due_date
      row :status
    end
    if resource.status != "paid"
      panel "Actions" do
        link_to "Mark as Paid",
                mark_as_paid_admin_rent_path(resource),
                method: :put,
                class: "button",
                data: { confirm: "Are you sure?" }
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :lease_agreement,
              as: :select,
              collection: LeaseAgreement.active.map { |la|
                [ "##{la.id} - Tenant: #{la.tenant.name}", la.id ]
              },
              prompt: "Select Lease Agreement"
      f.input :amount
      f.input :payment_date, as: :datepicker
      f.input :due_date, as: :datepicker
      f.input :status, as: :select, collection: %w[pending paid overdue]
    end
    f.actions
  end
end
