class PfbMercht < ApplicationRecord
  scope :valid_status, -> {where('status>0')}
  belongs_to :merchant
  belongs_to :org
end
