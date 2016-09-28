class KaifuResult < ApplicationRecord
  scope :show_order, -> {order('id desc')}
  scope :not_send, -> {where('status<5')}

  belongs_to :recv_post
  belongs_to :client
  belongs_to :client_payment

  def init_validate
    if self.status == 0 && (k = KaifuGateway.find_by(send_seq_id: self.org_send_seq_id))
      cp = k.client_payment
      self.client = cp.client
      self.organization_id = cp.org_id
      self.client_payment = cp
      self.notify_url = cp.notify_url
      self.org_send_seq_id = cp.order_id
      if self.notify_url.empty?
        self.status = 7
      end
    end

  end
end
