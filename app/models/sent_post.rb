class SentPost < ApplicationRecord
  scope :show_order, -> {order('id desc')}

  belongs_to :sender, polymorphic: true, optional: true
  has_one :http_log, as: :sender
end
