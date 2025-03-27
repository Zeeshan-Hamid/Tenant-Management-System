# frozen_string_literal: true

module LeaseAgreementManagementConcern
  extend ActiveSupport::Concern


  private

  def lease_agreement_params
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
    # Explicitly clear existing associations and set new ones
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

  # Methods for create action
  def create_tenant_from_params(tenant_attrs)
    tenant = Tenant.create!(tenant_attrs)
    tenant.activate
    tenant
  end

  def create_lease_agreement(permitted_params, tenant)
    lease_agreement = LeaseAgreement.new(permitted_params.except(:unit_ids))
    lease_agreement.tenant = tenant
    lease_agreement.status = "Active"
    lease_agreement.save!
    lease_agreement
  end

  def assign_units_to_lease(lease_agreement, unit_ids)
    lease_agreement.unit_ids = unit_ids
    lease_agreement.units.each do |unit|
      unit.update!(status: :on_rent)
    end
  end

  def handle_create_error(e, permitted_params)
    Rails.logger.error "RecordInvalid: #{e.message}"
    flash[:error] = e.message
    @lease_agreement ||= LeaseAgreement.new(permitted_params)
    render :new
  end

  def handle_create_success(tenant)
    redirect_to admin_lease_agreements_path,
                notice: "Lease agreement created successfully for tenant #{tenant.name}."
  end

  def validate_units_presence(unit_ids, permitted_params)
    if unit_ids.blank?
      flash[:error] = "Please select at least one unit."
      @lease_agreement = LeaseAgreement.new(permitted_params)
      render :new and return false
    end
    true
  end
end
