class CreateUserLeaseAgreements < ActiveRecord::Migration[7.2]
  def change
    create_table :user_lease_agreements do |t|
      t.references :user_property, null: false, foreign_key: true
      t.references :lease_agreement, null: false, foreign_key: true

      t.timestamps
    end
  end
end
