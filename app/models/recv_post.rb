class RecvPost < ActiveRecord::Base
  scope :show_order, -> {order('id desc')}

end
