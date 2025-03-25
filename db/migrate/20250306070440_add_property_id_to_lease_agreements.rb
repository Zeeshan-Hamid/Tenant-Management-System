class AddPropertyIdToLeaseAgreements < ActiveRecord::Migration[7.2]
  def change
    add_reference :lease_agreements, :property, foreign_key: true
  end
end
