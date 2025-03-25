# config/initializers/public_activity_ransack.rb
PublicActivity::Activity.class_eval do
    def self.ransackable_associations(auth_object = nil)
      # Allowlist associations that you are comfortable making searchable.
      # Adjust these associations based on your app's needs and security considerations.
      [ "owner", "recipient", "trackable" ]
    end

    def self.ransackable_attributes(auth_object = nil)
        [ "created_at", "id", "key", "owner_id", "owner_type", "parameters", "recipient_id", "recipient_type", "trackable_id", "trackable_type",
"updated_at" ]
      end
  end
