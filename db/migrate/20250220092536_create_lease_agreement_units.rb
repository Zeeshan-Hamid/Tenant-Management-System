class CreateLeaseAgreementUnits < ActiveRecord::Migration[7.2]
  def change
    create_table :lease_agreement_units do |t|
      t.references :lease_agreement, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end
  end
end
