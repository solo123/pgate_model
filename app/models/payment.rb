class Payment < ApplicationRecord
  belongs_to :pay_recv, required: true
  belongs_to :card, optional: true
  belongs_to :pay_result
  belongs_to :org, required: true
end
