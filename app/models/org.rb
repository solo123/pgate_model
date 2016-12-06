class Org < ApplicationRecord
  scope :show_order, -> {order('id desc')}
  scope :valid_status, -> {where('status>0')}
  has_many :payments
  has_one :merchant
  has_one :pfb_mercht
  has_one :zx_mct
  has_many :attachments, as: :attach_owner

  accepts_nested_attributes_for :merchant
  def status_enum
    {'开通': 1, '关闭': 0}
  end

end
