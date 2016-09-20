class KaifuGateway < ApplicationRecord
  belongs_to :client_payment
  scope :show_order, -> {order('id desc')}

end
