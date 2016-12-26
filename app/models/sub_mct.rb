class SubMct < ApplicationRecord
  belongs_to :org
  belongs_to :bank_mct, polymorphic: true
end
