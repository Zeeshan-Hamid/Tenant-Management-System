class AddIncrementTypeToLeaseAgreements < ActiveRecord::Migration[7.2]
  def change
    add_column :lease_agreements, :increment_type, :string
  end
end
