class SubMct < ApplicationRecord
  belongs_to :org
  belongs_to :bank_mct, polymorphic: true
  def clearing_type_enum
    {'T1': 1, 'D0': 2}
  end

end
