class PaymentQuery < ApplicationRecord
  belongs_to :client
  belongs_to :client_payment
  has_one :kaifu_query

  def check_query_fields
    client_payment = ClientPayment.find_by(client: client, order_id: order_id)
    unless client_payment
      return {resp_code: '13', resp_desc: '没有找到订单：' + order_id.to_s}
    end
    return {resp_code: '00'}
  end

end
