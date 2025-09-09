# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.
    user ||= User.new # guest user (not logged in)
    
    if user.is_admin?
      # Admin can manage everything
      can :manage, :all
    elsif user.is_security?
      # Security can read most things but limited edit access
      can :read, :all
      can :manage, [User, Address, UserContribution]
    elsif user.is_warga?
      # Warga (residents) have very limited access, mostly their own data
      can :read, User, id: user.id
      can :read, Address, id: user.addresses.pluck(:id) if user.addresses.any?
      can :read, UserContribution, address_id: user.addresses.pluck(:id) if user.addresses.any?
    end
  end
end