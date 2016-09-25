class KaifuResult < ActiveRecord::Base
  scope :show_order, -> {order('id desc')}
  scope :not_send, -> {where('status<5')}

  belongs_to :recv_post
  belongs_to :client
  belongs_to :client_payment

  def init_validate
    if self.status == 0 && (cp = ClientPayment.find_by(order_id: self.org_send_seq_id))
      self.client = cp.client
      self.organization_id = cp.org_id
      self.client_payment = cp
      if kaifu_result.notify_url.empty?
        kaifu_result.status = 7
      end
    end

  end
end
