class NotifyRecv < ApplicationRecord
  scope :show_order, -> {order('id desc')}
  scope :not_send, -> {where(status: 0)}
  has_one :http_log, as: :sender
end
