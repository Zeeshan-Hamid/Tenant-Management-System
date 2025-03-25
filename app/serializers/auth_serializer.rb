class AuthSerializer < ActiveModel::Serializer
  attributes :token, :user

  def token
    JsonWebToken.encode(user_id: object.id)
  end

  def user
    {
      id: object.id,
      phone_number: object.phone_number,
      name: object.name,
      profile_completed: object.profile_completed
    }
  end
end
