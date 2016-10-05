class Recv1Post < ApplicationRecord
  scope :show_order, -> {order('id desc')}
end
