class KaifuSignin < ActiveRecord::Base
  scope :show_order, -> {order('id desc')}

end
