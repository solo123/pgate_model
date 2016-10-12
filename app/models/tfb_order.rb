class TfbOrder < ApplicationRecord
  belongs_to :client_payment
  scope :show_order, -> {order('id desc')}
  has_many :post_dats, as: :sender
  has_many :biz_errors, as: :error_source
end
