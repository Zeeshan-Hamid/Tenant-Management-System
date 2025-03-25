# frozen_string_literal: true

class UnitSerializer < ActiveModel::Serializer
  attributes :id, :property_id, :unit_number, :floor, :square_footage, :rental_rate,
             :selling_rate, :status
end
