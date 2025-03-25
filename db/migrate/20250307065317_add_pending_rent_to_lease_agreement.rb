class AddPendingRentToLeaseAgreement < ActiveRecord::Migration[7.2]
  def change
    add_column :lease_agreements, :pending_rent, :integer, null: false, default: 0
  end
end
