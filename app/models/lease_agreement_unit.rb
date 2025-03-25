# frozen_string_literal: true

class LeaseAgreementUnit < ApplicationRecord
  belongs_to :lease_agreement
  belongs_to :unit
end
