class ClientPayment < ApplicationRecord
  belongs_to :client
  has_one :kaifu_gateway
  scope :show_order, -> {order('id desc')}

  def return_json
    case status
    when 0
      {resp_code: '96', resp_desc: '系统故障，发送失败'}
    when 1, 8
      js = {
        org_id: org_id,
        trans_type: trans_type,
        order_time: order_time,
        order_id: order_id,
        amount: amount,
        fee: fee,
        resp_code: resp_code,
        resp_desc: resp_desc
      }
      js[:redirect_url] = redirect_url if redirect_url
      js[:img_url] = img_url if img_url
      if status == 8
        js[:pay_code] = pay_code
        js[:pay_desc] = pay_desc
        js[:t0_code] = t0_code if t0_code
        js[:t0_desc] = t0_desc if t0_desc
      end
      js
    when 7
      {resp_code: resp_code, resp_desc: resp_desc}
    else
      {resp_code: '96', resp_desc: '系统错误，status错'}
    end
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
