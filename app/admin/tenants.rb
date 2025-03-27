# frozen_string_literal: true

ActiveAdmin.register Tenant do
  actions :index, :show, :new, :create

  permit_params :name, :unit_id, :active, :phone, :email, :cnic, :receipt_image, :balance,
                lease_agreement_attributes: %i[
                  rent_amount start_date end_date security_deposit
                  increment_type annual_increment unit_id increment_frequency pending_rent
                ]

  scope :active, default: true do |tenants|
    tenants.where(active: true)
  end

  scope :inactive do |tenants|
    tenants.where(active: false)
  end

  index do
    selectable_column
    id_column
    column :name
    column :phone
    column "CNIC" do |tenant|
      tenant.cnic.present? ? tenant.cnic.sub(/(?<=^\d{5}-)\d{7}(?=-\d$)/, "*******") : ""
    end

    column :active
    column "Pending Rent" do |tenant|
      total_pending_rent = tenant.lease_agreements.sum(:pending_rent)
      number_to_currency(total_pending_rent, unit: "PKR", format: "%n %u")
    end
    column "Balance" do |tenant|
      number_to_currency(tenant.balance, unit: "PKR", format: "%n %u")
    end
    actions defaults: false do |tenant|
      item "View", admin_tenant_path(tenant)
    end
  end

  filter :name
  filter :phone
  filter :active

  show do
    attributes_table do
      row :name
      row :phone
      row("CNIC", &:cnic)
      row "Associated Property and Unit(s)" do |tenant|
        tenant.lease_agreements.map do |lease|
          property_and_units = lease.units.map do |unit|
            "#{unit.property.name} (Unit: #{unit.unit_number})"
          end.join(", ")
          "Lease ##{lease.id}: #{property_and_units}"
        end.join("<br>").html_safe
      end
      row "Lease Start Date" do |tenant|
        tenant.lease_agreements.map { |lease| lease.start_date.strftime("%Y-%m-%d") }.join(", ")
      end
      row "Lease End Date" do |tenant|
        tenant.lease_agreements.map { |lease| lease.end_date.strftime("%Y-%m-%d") }.join(", ")
      end

      row "Lease Status" do |tenant|
        tenant.lease_agreements.map { |lease| lease.status.present? ? lease.status : "Active" }.join(", ")
      end

      row "Rent Amount" do |tenant|
        tenant.lease_agreements.map do |lease|
          number_to_currency(lease.rent_amount, unit: "PKR", format: "%n %u")
        end.join(", ")
      end
      row "Pending Rent" do |tenant|
        total_pending_rent = tenant.lease_agreements.sum(:pending_rent)
        number_to_currency(total_pending_rent, unit: "PKR", format: "%n %u")
      end
    end

    panel "Payment History" do
      table_for resource.rents.order("payment_date DESC") do
        column "Payment Date" do |rent|
          rent.payment_date.strftime("%B %d, %Y")
        end
        column "Amount" do |rent|
          number_to_currency(rent.amount, unit: "PKR", format: "%n %u")
        end
        column "Status" do |rent|
          status_tag(rent.status, class: rent.status == "paid" ? "ok" : (rent.status == "overdue" ? "error" : "warning"))
        end
        column "Payment Method" do |rent|
          rent.payment_method.present? ? rent.payment_method.humanize : "Not specified"
        end
        column "Lease" do |rent|
          if rent.lease_agreement
            lease = rent.lease_agreement
            property_names = lease.units.map { |unit| unit.property.name }.uniq.join(", ")
            unit_numbers = lease.units.map(&:unit_number).join(", ")
            "#{property_names} (Units: #{unit_numbers})"
          else
            "Unknown"
          end
        end
      end
    end

    panel "Receipt Images" do
      if resource.receipt_image.present?
        resource.receipt_image.map { |url| link_to(url, url, target: "_blank") }.join("<br>").html_safe
      else
        "No receipt images"
      end
    end

    active_admin_comments
  end

  form do |f|
    f.inputs "Tenant Details" do
      f.input :name
      f.input :phone
      f.input :email
      f.input :cnic, label: "CNIC Number", hint: "Format: XXXXX-XXXXXXX-X"
      f.input :active
    end

    f.inputs "Lease Agreement", for: [ :lease_agreements, LeaseAgreement.new ] do |lease_form|
      lease_form.input :rent_amount
      lease_form.input :start_date, as: :datepicker
      lease_form.input :end_date, as: :datepicker
      lease_form.input :security_deposit
      lease_form.input :increment_frequency, as: :select, collection: %w[quarterly yearly],
                                             include_blank: false
      lease_form.input :increment_type, as: :select, collection: %w[fixed percentage],
                                        include_blank: false
      lease_form.input :annual_increment
      lease_form.input :unit_id, as: :hidden, input_html: { value: params[:unit_id] }
    end
    f.actions
  end

  controller do
    def create
      @unit = Unit.find(params[:unit_id]) if params[:unit_id].present?
      @tenant = if @unit
                  @unit.tenants.new(tenant_params)
      else
                  Tenant.new(tenant_params)
      end

      if @tenant.save
        @tenant.activate
        redirect_to admin_tenant_path(@tenant), notice: "Tenant added successfully."
      else
        render :new
      end
    end

    private

    def tenant_params
      params.require(:tenant).permit(
        :name, :phone, :email, :cnic,
        lease_agreement_attributes: %i[
          rent_amount start_date end_date security_deposit
          increment_type annual_increment unit_id increment_frequency pending_rent
        ]
      )
    end
  end
end
