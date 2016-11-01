class Org < ApplicationRecord
  scope :valid_status, -> {where('status>0')}
  has_many :payments
end
