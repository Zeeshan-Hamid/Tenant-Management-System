# frozen_string_literal: true

ActiveAdmin.register LeaseAgreement do
  config.clear_action_items!

  actions :all, except: [ :destroy ]

  permit_params :property_id, :tenant_id, :start_date, :end_date, :rent_amount, :pending_rent,
                :security_deposit, :annual_increment, :increment_frequency,
                :increment_type, :status, unit_ids: [],
                                          tenant_attributes: %i[id name phone cnic email _destroy]

  scope :active_agreements, default: true
  scope :deactivated_agreements

  remove_filter :lease_agreement_units
  remove_filter :units

  filter :start_date
  filter :end_date
  filter :rent_amount
  filter :tenant, as: :select, collection: proc { Tenant.all }

  index do
    selectable_column
    id_column
    column "Properties" do |lease|
      lease.units.map { |unit| unit.property.name }.uniq.join(", ")
    end
    column "Units" do |lease|
      lease.units.map(&:unit_number).join(", ")
    end
    column "Tenant" do |lease|
      lease.tenant.name
    end
    column :start_date
    column :end_date
    column :rent_amount
    column :pending_rent
    actions defaults: false do |lease|
      item "View", admin_lease_agreement_path(lease), style: "margin-right: 10px;"
      if lease.active?
        item "Edit", edit_admin_lease_agreement_path(lease), style: "margin-right: 10px;"
        item "Deactivate", deactivate_admin_lease_agreement_path(lease),
             method: :put,
             data: { confirm: "Are you sure you want to deactivate this lease agreement? This action will free all associated units." },
             style: "margin-right: 10px;"
      end
    end
  end

  show do |lease|
    attributes_table do
      row "Properties" do |l|
        l.units.map { |u| u.property.name }.uniq.join(", ")
      end
      row "Units Number" do |l|
        l.units.map(&:unit_number).join(", ")
      end
      row "Tenant" do |l|
        l.tenant.name
      end
      row :start_date
      row :end_date
      row :rent_amount
      row :pending_rent
      row :security_deposit
      row :status
      row :created_at
      row :updated_at
      row :annual_increment
      row :increment_frequency
      row :increment_type
    end

    panel "Rent History" do
      table_for lease.rents.order(payment_date: :desc) do
        column "Month" do |rent|
          rent.rent_name&.present? ? rent.rent_name.capitalize : rent.payment_date.strftime("%b %Y")
        end
        column "Rent Amount" do |rent|
          number_to_currency(rent.amount, unit: "PKR", format: "%n %u")
        end
        column "Status" do |rent|
          status_tag rent.status == "paid" ? "Paid" : (rent.status == "pending" ? "Pending" : (rent.status == "overdue" ? "Overdue" : rent.status)), 
            class: rent.status == "paid" ? "ok" : (rent.status == "pending" ? "warning" : (rent.status == "overdue" ? "error" : nil))
        end
        column "Paid Date" do |rent|
          rent.status == "paid" ? rent.payment_date.strftime("%B %d, %Y") : "-"
        end
        column "Due Date" do |rent|
          rent.due_date.strftime("%B %d, %Y") if rent.due_date
        end
        column "Amount Paid" do |rent|
          if rent.amount_paid && rent.amount_paid > 0
            number_to_currency(rent.amount_paid, unit: "PKR", format: "%n %u")
          else
            "-"
          end
        end
        column "Payment Method" do |rent|
          rent.payment_method&.humanize || "-"
        end
      end
    end

    panel "Payment History Ledger" do
      tenant = lease.tenant
      rents = lease.rents.order(:payment_date)
      ledger_entries = calculate_payment_ledger(lease)

      table_for ledger_entries do
        column "Date" do |entry|
          entry[:date].strftime("%B %d, %Y")
        end
        column "Standard Rent" do |entry|
          number_to_currency(entry[:standard_rent], unit: "PKR", format: "%n %u")
        end
        column "Adjusted Total Rental Amount" do |entry|
          number_to_currency(entry[:adjusted_total], unit: "PKR", format: "%n %u")
        end
        column "Amount Paid" do |entry|
          if entry[:amount_paid] > 0
            number_to_currency(entry[:amount_paid], unit: "PKR", format: "%n %u")
          else
            status_tag("Not Paid", class: "error")
          end
        end
        column "Amount Pending" do |entry|
          if entry[:amount_pending] > 0
            amount_text = number_to_currency(entry[:amount_pending], unit: "PKR", format: "%n %u")
            status_tag(amount_text, class: "error")
          else
            status_tag("Paid in Full", class: "ok")
          end
        end
        column "Tenant Balance" do |entry|
          if entry[:tenant_balance] > 0
            amount_text = number_to_currency(entry[:tenant_balance], unit: "PKR", format: "%n %u")
            status_tag(amount_text, class: "ok")
          else
            "0 PKR"
          end
        end
        column "Status" do |entry|
          status_tag entry[:status] == "paid" ? "Paid" : (entry[:status] == "pending" ? "Pending" : (entry[:status] == "overdue" ? "Overdue" : entry[:status])), 
            class: entry[:status] == "paid" ? "ok" : (entry[:status] == "pending" ? "warning" : (entry[:status] == "overdue" ? "error" : nil))
        end
      end
    end

    active_admin_comments
  end

  action_item :new, only: :index do
    link_to "New Lease Agreement", new_admin_lease_agreement_path
  end

  action_item :edit, only: :show, if: proc { resource.active? } do
    link_to "Edit Lease Agreement", edit_admin_lease_agreement_path(resource)
  end

  action_item :deactivate, only: :show, if: proc { resource.active? } do
    link_to "Deactivate Lease Agreement", deactivate_admin_lease_agreement_path(resource),
            method: :put,
            data: { confirm: "Are you sure you want to deactivate this lease agreement? This action will free all associated units." }
  end

  controller do
    helper_method :calculate_payment_ledger, :get_available_property_units, 
                  :get_available_units_for_property, :unit_available_for_lease?, 
                  :get_current_property_id, :combine_and_unique_units

    def create
      permitted = permit_params.except(:id)
      ActiveRecord::Base.transaction do
        unit_ids = process_unit_ids(permitted)
        validate_unit_selection(unit_ids)
        create_lease_agreement_with_tenant(permitted, unit_ids)
      end
    rescue ActiveRecord::RecordInvalid => e
      handle_create_error(e, permitted)
    rescue ActiveRecord::RecordNotFound => e
      handle_record_not_found_error(e, permitted)
    end

    def update
      @lease_agreement = LeaseAgreement.find(params[:id])
      unit_ids = process_unit_ids(permit_params)

      if unit_ids.blank?
        flash[:error] = "Please select at least one unit."
        render :edit and return
      end

      ActiveRecord::Base.transaction do
        update_tenant(permit_params[:tenant_attributes])
        process_unit_changes(unit_ids)
        update_lease_details(permit_params)

        redirect_to admin_lease_agreement_path(@lease_agreement),
                    notice: "Lease agreement was successfully updated."
      end
    rescue ActiveRecord::RecordInvalid => e
      handle_update_error(e)
    end

    def edit
      @lease_agreement = LeaseAgreement.find_by(id: params[:id])
      unless @lease_agreement
        redirect_to admin_lease_agreements_path, alert: "Lease agreement not found." and return
      end
      unless @lease_agreement.active?
        redirect_to admin_lease_agreement_path(@lease_agreement),
                    alert: "Deactivated lease agreements cannot be edited." and return
      end
      super
    end

    def index
      params[:q].delete("lease_agreement_units_id_eq") if params[:q].present?
      super
    end

    def permit_params
      params.require(:lease_agreement).permit(
        :property_id, :start_date, :end_date, :rent_amount, :security_deposit, :annual_increment,
        :increment_frequency, :increment_type,
        unit_ids: [],
        tenant_attributes: %i[id name phone cnic email]
      )
    end

    def process_unit_ids(params_hash)
      (params_hash[:unit_ids] || []).flatten.reject(&:blank?).map(&:to_i).uniq
    end

    def update_unit_statuses(units_to_remove, units_to_add)
      Unit.where(id: units_to_remove).update_all(status: :available_for_rent) if units_to_remove.present?
      Unit.where(id: units_to_add).update_all(status: :on_rent) if units_to_add.present?
    end

    def validate_unit_selection(unit_ids)
      if unit_ids.blank?
        flash[:error] = "Please select at least one unit."
        @lease_agreement = LeaseAgreement.new(permitted)
        render :new and return false
      end
      true
    end

    def create_lease_agreement_with_tenant(permitted, unit_ids)
      tenant_attrs = permitted.delete(:tenant_attributes)
      tenant = Tenant.create!(tenant_attrs)
      tenant.activate
      
      @lease_agreement = LeaseAgreement.new(permitted.except(:unit_ids))
      @lease_agreement.tenant = tenant
      @lease_agreement.status = "Active"
      @lease_agreement.save!
      @lease_agreement.unit_ids = unit_ids
      
      @lease_agreement.units.each do |unit|
        unit.update!(status: :on_rent)
      end
      
      redirect_to admin_lease_agreements_path,
                  notice: "Lease agreement created successfully for tenant #{tenant.name}."
    end

    def handle_create_error(exception, permitted)
      Rails.logger.error "RecordInvalid: #{exception.message}"
      flash[:error] = exception.message
      @lease_agreement ||= LeaseAgreement.new(permitted)
      render :new
    end

    def handle_record_not_found_error(exception, permitted)
      flash[:error] = exception.message
      @lease_agreement = LeaseAgreement.new(permitted)
      render :new
    end

    def update_tenant(tenant_attributes)
      @lease_agreement.tenant.update!(tenant_attributes)
    end

    def process_unit_changes(new_unit_ids)
      old_unit_ids = @lease_agreement.unit_ids.dup
      units_to_remove = old_unit_ids - new_unit_ids
      units_to_add = new_unit_ids - old_unit_ids

      update_unit_statuses(units_to_remove, units_to_add)
      update_lease_units(new_unit_ids)
    end

    def update_lease_units(unit_ids)
      @lease_agreement.units = Unit.where(id: unit_ids)
    end

    def update_lease_details(permitted_params)
      lease_params = permitted_params.except(:tenant_attributes, :unit_ids)
      @lease_agreement.update!(lease_params)
    end

    def handle_update_error(exception)
      Rails.logger.error "RecordInvalid: #{exception.message}"
      flash.now[:error] = exception.message
      render :edit
    end

    def calculate_payment_ledger(lease_agreement)
      ledger_entries = []
      tenant = lease_agreement.tenant
      rents = lease_agreement.rents.order(:payment_date)

      carry = 0.0

      rents.each do |rent|
        ledger_entry = create_ledger_entry(rent, tenant, carry)
        ledger_entries << ledger_entry
        
        if ledger_entry[:amount_paid] < ledger_entry[:adjusted_total]
          carry = 0.0
        else
          carry = ledger_entry[:amount_paid] - ledger_entry[:adjusted_total]
        end
      end

      add_current_month_if_needed(ledger_entries, lease_agreement, tenant, carry)
      
      ledger_entries
    end

    def create_ledger_entry(rent, tenant, carry)
      standard_rent = rent.amount.to_f
      adjusted_total = calculate_adjusted_total(standard_rent, carry)
      amount_paid = rent.status == "paid" ? rent.amount_paid.to_f : 0.0

      amount_pending = if amount_paid < adjusted_total
                         adjusted_total - amount_paid
                       else
                         0.0
                       end

      {
        date: rent.payment_date,
        standard_rent: standard_rent,
        adjusted_total: adjusted_total,
        amount_paid: amount_paid,
        amount_pending: amount_pending,
        tenant_balance: tenant.balance.to_f,
        status: rent.status
      }
    end

    def calculate_adjusted_total(standard_rent, carry)
      adjusted_total = standard_rent - carry
      adjusted_total.negative? ? 0.0 : adjusted_total
    end

    def add_current_month_if_needed(ledger_entries, lease_agreement, tenant, carry)
      current_month_start = Date.current.beginning_of_month
      if ledger_entries.empty? || ledger_entries.last[:date] < current_month_start
        standard_rent = lease_agreement.rent_amount.to_f
        adjusted_total = calculate_adjusted_total(standard_rent, carry)

        ledger_entries << {
          date: current_month_start,
          standard_rent: standard_rent,
          adjusted_total: adjusted_total,
          amount_paid: 0.0,
          amount_pending: adjusted_total,
          tenant_balance: tenant.balance.to_f,
          status: "pending"
        }
      end
    end

    def deactivate_lease_agreement(lease)
      ActiveRecord::Base.transaction do
        lease.update!(status: "Deactivated")
        update_units_on_deactivation(lease)
        lease.tenant.update!(active: false)
        remove_lease_from_users(lease)
      end
    end

    def update_units_on_deactivation(lease)
      lease.units.each do |unit|
        unit.update!(status: :available_for_rent)
      end
    end

    def remove_lease_from_users(lease)
      user_lease_agreements = UserLeaseAgreement.where(lease_agreement_id: lease.id)
      
      user_property_ids = user_lease_agreements.pluck(:user_property_id)
      
      user_lease_agreements.destroy_all
      
      UserProperty.where(id: user_property_ids).each do |user_property|
        active_lease_ids = LeaseAgreement.active_agreements
                                        .joins(:user_lease_agreements)
                                        .where(user_lease_agreements: { user_property_id: user_property.id })
                                        .pluck(:id)
        
        user_property.destroy if active_lease_ids.empty?
      end
    end

    def get_available_property_units(lease_agreement)
      # Get all property and unit info for available units or already assigned units to this lease
      result = {}

      properties = Property.all
      properties.each do |property|
        available_units = get_available_units_for_property(property, lease_agreement)
        next if available_units.empty?
        
        result[property] = available_units
      end

      result
    end

    def get_available_units_for_property(property, lease_agreement)
      # Combine and unique units that are:
      # 1. Available for rent
      # 2. Already assigned to this lease
      units_for_property = combine_and_unique_units(
        property.units.available_for_rent,
        lease_agreement && lease_agreement.units.where(property_id: property.id) || []
      )

      # Sort by unit number
      units_for_property.sort_by(&:unit_number)
    end

    def unit_available_for_lease?(unit, lease_agreement)
      # A unit is available for a lease if:
      # 1. It's available for rent
      # 2. It's already assigned to this lease
      unit.available_for_rent? || 
        (lease_agreement && lease_agreement.units.include?(unit))
    end

    def get_current_property_id
      # Return the property ID from params if it exists
      params[:lease_agreement] && params[:lease_agreement][:property_id].presence
    end

    def combine_and_unique_units(*unit_collections)
      unit_collections.flatten.uniq
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.to_hash.keys)
    
    f.inputs "Property and Units" do
      property_id = if f.object.units.any?
                      f.object.units.first.property_id
                    else
                      nil
                    end
      f.input :property_id, as: :hidden, input_html: { id: "property_selector_hidden", value: property_id }

      controller = ActiveAdmin.application.namespace(:admin).resource_for(LeaseAgreement).controller
      available_property_units = controller.new.send(:get_available_property_units, f.object)

      render partial: "admin/lease_agreements/property_units_selector",
             locals: { f: f, lease_agreement: f.object,
                       available_property_units: available_property_units }
    end
    
    f.inputs "Tenant Details", for: [ :tenant, f.object.tenant || Tenant.new ] do |tenant_form|
      tenant_form.input :name, label: "Tenant Name"
      tenant_form.input :phone, label: "Mobile Number", hint: "11 digits"
      tenant_form.input :cnic, label: "CNIC Number", hint: "Format: XXXXX-XXXXXXX-X"
    end
    
    f.inputs "Lease Agreement Details" do
      f.input :start_date, as: :datepicker
      f.input :end_date, as: :datepicker
      f.input :rent_amount, min: 1
      f.input :increment_frequency,
              as: :select,
              collection: LeaseAgreement.increment_frequencies.keys.map { |key|
                [ key.humanize, key ]
              },
              include_blank: false
      f.input :increment_type,
              as: :select,
              collection: LeaseAgreement.increment_types.keys.map { |key| [ key.humanize, key ] },
              include_blank: false
      f.input :security_deposit, min: 1
      f.input :annual_increment, hint: "Optional"
    end
    
    f.actions
  end
  
  member_action :deactivate, method: :put do
    lease = LeaseAgreement.find_by(id: params[:id])
    unless lease
      redirect_to admin_lease_agreements_path, alert: "Lease agreement not found." and return
    end

    begin
      deactivate_lease_agreement(lease)
      redirect_to admin_lease_agreement_path(lease),
                notice: "Lease agreement deactivated, tenant deactivated, units made available, and user associations removed."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_lease_agreement_path(lease),
                alert: "Failed to deactivate lease agreement: #{e.message}"
    end
  end
end
