class RemoveUnitIdFromLeaseAgreements < ActiveRecord::Migration[7.2]
  def change
    remove_column :lease_agreements, :unit_id, :bigint
  end
end
