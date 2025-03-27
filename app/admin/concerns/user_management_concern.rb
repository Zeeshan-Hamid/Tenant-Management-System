# frozen_string_literal: true

module UserManagementConcern
  extend ActiveSupport::Concern

  private

  # Core functionality methods
  def prepare_form_data
    initialize_user_properties(@user, @properties)
    prepare_available_leases
  end

  def save_user_with_properties
    prepare_available_leases
    filter_user_properties!
    @user.save
  end

  def redirect_to_user_path_with_notice(message)
    redirect_to admin_user_path(@user), notice: message
  end

  # Property loading and management
  def load_properties
    @properties = fetch_available_properties
  end

  def fetch_available_properties
    assigned_lease_ids = fetch_assigned_lease_ids
    available_properties = fetch_properties_with_unassigned_active_leases(assigned_lease_ids)
    
    if user_persisted?
      add_user_properties_to_available(available_properties)
    else
      available_properties
    end
  end

  def fetch_assigned_lease_ids
    assigned_ids = UserLeaseAgreement.pluck(:lease_agreement_id)
    
    if should_exclude_current_user_leases?
      current_user_lease_ids = @user.lease_agreements.active.pluck(:id)
      assigned_ids -= current_user_lease_ids
    end
    
    assigned_ids
  end

  def should_exclude_current_user_leases?
    @user.present? && (action_name == "edit" || action_name == "update")
  end

  def fetch_properties_with_unassigned_active_leases(assigned_lease_ids)
    Property.all.select do |property|
      property.lease_agreements.active.any? { |la| !assigned_lease_ids.include?(la.id) }
    end
  end

  def user_persisted?
    @user.present? && @user.persisted?
  end

  def add_user_properties_to_available(available_properties)
    user_property_ids = @user.properties.pluck(:id)
    user_properties = Property.where(id: user_property_ids)
    (available_properties + user_properties).uniq
  end

  # User management
  def set_user
    @user = User.find_by(id: params[:id])

    unless @user
      flash[:error] = "User not found."
      redirect_to admin_users_path and return
    end
  end

  # Params processing
  def process_user_properties_params
    property_to_user_property = build_property_to_user_property_map

    if user_properties_params_present?
      update_user_properties_attributes(property_to_user_property)
    end
  end

  def user_properties_params_present?
    params[:user] && params[:user][:user_properties_attributes].present?
  end

  def update_user_properties_attributes(property_map)
    params[:user][:user_properties_attributes].each do |key, attrs|
      property_id = attrs[:property_id].to_s

      if existing_up = property_map[property_id]
        update_existing_user_property(attrs, existing_up)
      end
    end
  end

  def update_existing_user_property(attrs, existing_user_property)
    attrs[:id] = existing_user_property.id

    # Ensure that any lease_agreement_ids is filtered to only include active ones
    if attrs[:lease_agreement_ids].present?
      attrs[:lease_agreement_ids] = filter_active_lease_agreements(attrs[:lease_agreement_ids])
    end

    mark_for_destruction_if_empty(attrs)
  end

  def filter_active_lease_agreements(lease_agreement_ids)
    active_ids = LeaseAgreement.active.where(id: lease_agreement_ids).pluck(:id).map(&:to_s)
    lease_agreement_ids.select { |id| active_ids.include?(id.to_s) }
  end

  def build_property_to_user_property_map
    property_map = {}
    @user.user_properties.each do |up|
      property_map[up.property_id.to_s] = up
    end
    property_map
  end

  def mark_for_destruction_if_empty(attrs)
    if attrs[:lease_agreement_ids].blank? || attrs[:lease_agreement_ids].reject(&:blank?).empty?
      attrs[:_destroy] = "1"
    end
  end

  # User properties initialization
  def initialize_user_properties(user, properties)
    return unless user.present?
    return if user.persisted? && params[:action] == "update"

    existing_property_ids = user.user_properties.map(&:property_id).map(&:to_s)

    properties.each do |property|
      property_id_str = property.id.to_s
      next if existing_property_ids.include?(property_id_str)
      user.user_properties.build(property: property)
    end
  end

  # Available leases preparation
  def prepare_available_leases
    return unless @user.present?

    @available_lease_agreements = {}
    other_user_lease_ids = get_other_users_lease_ids

    @properties.each do |property|
      process_property_leases(property, other_user_lease_ids)
    end
  end

  def process_property_leases(property, other_user_lease_ids)
    available_leases = get_available_leases_for_property(property, other_user_lease_ids)
    return unless available_leases.any?

    user_property = find_or_build_user_property(property)
    return unless user_property

    @available_lease_agreements[property.id] = available_leases
  end

  def get_other_users_lease_ids
    if @user.persisted?
      UserLeaseAgreement.where.not(user_property: @user.user_properties).pluck(:lease_agreement_id)
    else
      UserLeaseAgreement.pluck(:lease_agreement_id)
    end
  end

  def get_available_leases_for_property(property, other_user_lease_ids)
    # Get all active lease agreements for this property that aren't assigned to other users
    available_lease_agreements = property.lease_agreements.active.where.not(id: other_user_lease_ids)

    if @user.persisted?
      include_current_user_leases(property, available_lease_agreements)
    else
      available_lease_agreements
    end
  end

  def include_current_user_leases(property, available_lease_agreements)
    user_property = @user.user_properties.find_by(property_id: property.id)

    if user_property.present?
      property_lease_ids = user_property.lease_agreements.active.pluck(:id)

      currently_assigned = LeaseAgreement.active.where(id: property_lease_ids)

      (available_lease_agreements + currently_assigned).uniq
    else
      available_lease_agreements
    end
  end

  def find_or_build_user_property(property)
    user_property = @user.user_properties.find { |up| up.property_id == property.id }

    return user_property if user_property.present?
    return nil unless @user.new_record?

    @user.user_properties.build(property: property)
  end

  # User properties filtering
  def filter_user_properties!
    return unless @user.present?

    @user.user_properties.each do |up|
      filter_lease_agreements_for_user_property(up)
    end
  end

  def filter_lease_agreements_for_user_property(user_property)
    lease_agreement_ids = user_property.lease_agreement_ids.reject(&:blank?)
    
    active_lease_ids = LeaseAgreement.active.where(id: lease_agreement_ids).pluck(:id)
    
    if active_lease_ids.empty?
      user_property.mark_for_destruction
    else
      user_property.lease_agreement_ids = active_lease_ids
    end
  end
end
