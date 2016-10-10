class KaifuGateway < ApplicationRecord
  belongs_to :client_payment
  scope :show_order, -> {order('id desc')}
  has_many :post_data, as: :sender
end
