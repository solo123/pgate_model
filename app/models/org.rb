class Org < ApplicationRecord
  scope :valid_status, -> {where('status>0')}
  has_many :payments
  has_one :merchant
  has_one :pfb_mercht
end
