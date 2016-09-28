class KaifuSignin < ApplicationRecord
  scope :show_order, -> {order('id desc')}

end
