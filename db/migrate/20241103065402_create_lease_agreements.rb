class CreateLeaseAgreements < ActiveRecord::Migration[7.2]
  def change
    create_table :lease_agreements do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :rent_amount
      t.decimal :security_deposit
      t.string :status

      t.timestamps
    end
  end
end
