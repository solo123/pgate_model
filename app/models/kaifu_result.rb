class KaifuResult < ApplicationRecord
  scope :show_order, -> {order('id desc')}
  scope :not_send, -> {where('status<5')}

  belongs_to :sender, polymorphic: true
  belongs_to :client
  belongs_to :client_payment
  belongs_to :kaifu_gateway

  def init_data
    if status == 0 && (k = KaifuGateway.find_by(send_seq_id: org_send_seq_id))
      self.kaifu_gateway = k
      cp = k.client_payment
      self.client = cp.client
      self.client_payment = cp
      self.notify_url = cp.notify_url
      if self.notify_url.empty?
        status = 7
      end
    end
  end
end
