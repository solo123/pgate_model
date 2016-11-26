class Merchant < ApplicationRecord
  scope :valid_status, -> {where('status>0')}
  belongs_to :org
end
