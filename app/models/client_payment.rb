class ClientPayment < ActiveRecord::Base
  belongs_to :client

  def tst
    self.fee = 101
  end

  def check_payment_fields
    if trans_type == 'P001'
      return check_p001
    else
      return {resp_code: '12', resp_desc: '无此交易: ' + trans_type}
    end
  end

  def check_p001
    fields = %W(order_time order_id order_title pay_pass amount fee card_no card_holder_name person_id_num notify_url callback_url mac)
    miss_flds =  []
    fields.each {|fld| miss_flds << fld if self[fld].nil? }
    if miss_flds.length > 0
      status = 7
      js = {resp_code: '30', resp_desc: '缺少必须的字段: ' + miss_flds.join(', ') }
    else
      client = Client.find_by(org_id: org_id)
      lowest_fee = self.amount * client.d0_min_percent / 1000000 + client.d0_min_fee
      if self.fee < lowest_fee
        js = {resp_code: '30', resp_desc: '手续费不正确: ' + lowest_fee.to_s}
      else
        js = {resp_code: '00'}
      end
    end
    return js
  end
end
