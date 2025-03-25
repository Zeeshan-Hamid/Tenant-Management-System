class UpdateRentsForLeaseAgreement < ActiveRecord::Migration[7.2]
  def change
    remove_reference :rents, :unit, foreign_key: true
    remove_reference :rents, :tenant, foreign_key: true
    add_reference :rents, :lease_agreement, null: false, foreign_key: true
  end
end
