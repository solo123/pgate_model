class RecvPost < ApplicationRecord
  scope :show_order, -> {order('id desc')}
  scope :not_send, -> {where(status: 0)}
  has_one :kaifu_result

end
