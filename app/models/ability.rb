# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(current_admin_user)
    current_admin_user ||= AdminUser.new

    can :read, ActiveAdmin::Page, name: "Dashboard"

    if current_admin_user.administrator?
      # Level 1
      can :manage, :all
    elsif current_admin_user.property_manager?
      # Level 2
      can :manage, Property
      can :manage, User
      can :manage, Unit
      can :manage, LeaseAgreement
      can :manage, PublicActivity
      can :manage, Rent
    elsif current_admin_user.unit_manager?
      # Level 3
      can :manage, Unit
      can :manage, LeaseAgreement
      can :manage, Tenant
      can :manage, Rent
    end
  end
end
