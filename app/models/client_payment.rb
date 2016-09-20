class ClientPayment < ActiveRecord::Base
  belongs_to :client
  scope :show_order, -> {order('id desc')}

  def check_payment_fields
    case trans_type
    when 'P001'
      return check_p001
    when 'P002'
      return check_p002
    else
      return {resp_code: '12', resp_desc: '无此交易: ' + trans_type}
    end
  end

  def check_p001
    return check_field_and_fee %W(order_time order_id order_title pay_pass amount fee card_no card_holder_name person_id_num notify_url callback_url mac)
  end
  def check_p002
    return check_field_and_fee %W(order_time order_id order_title pay_pass amount fee notify_url callback_url mac)
  end
  def check_field_and_fee(fields)
    miss_flds =  []
    fields.each {|fld| miss_flds << fld if self[fld].nil? }
    if miss_flds.length > 0
      status = 7
      js = {resp_code: '30', resp_desc: '缺少必须的字段: ' + miss_flds.join(', ') }
    else
      client = Client.find_by(org_id: org_id)
      js = check_fee
    end
    return js
  end
  def check_fee
    lowest_fee = self.amount * client.d0_min_percent / 1000000 + client.d0_min_fee
    if self.fee < lowest_fee
      js = {resp_code: '30', resp_desc: '手续费不正确: ' + lowest_fee.to_s}
    else
      js = {resp_code: '00'}
    end
    js
  end
end
