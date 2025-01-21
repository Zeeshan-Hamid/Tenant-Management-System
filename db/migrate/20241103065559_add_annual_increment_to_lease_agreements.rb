class AddAnnualIncrementToLeaseAgreements < ActiveRecord::Migration[7.2]
  def change
    add_column :lease_agreements, :annual_increment, :decimal
    add_column :lease_agreements, :increment_frequency, :string
  end
end
