module Biz
  class KaiFuApi
    ORG_ID = 'puerhanda'
    TMK = '9DB9095654D1FA7763F32E6B4E922140'
    API_URL_OPENID = 'http://61.135.202.242/payform/organization_ymf'
    NOTIFY_URL = 'http://112.74.184.236:8010/recv_notify'
    CALLBACK_URL = 'http://112.74.184.236:8010/recv_callback'
    OPENID_B001_FLDS = "sendTime,sendSeqId,transType,organizationId,payPass,transAmt,fee,cardNo,name,idNum,body,notifyUrl,callbackUrl"

    def send_kaifu_payment(client_payment)
      if client_payment.trans_type == 'P001'
        create_b001(client_payment)
      end
    end
    def create_b001(client_payment)
      gw = KaifuGateway.new(
        client_payment_id: client_payment.id,
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P1" + ('%06d' % client_payment.id),
        trans_type: 'B001',
        organization_id: ORG_ID,
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount,
        fee: client_payment.fee,
        card_no: client_payment.card_no,
        name: client_payment.card_holder_name,
        id_num: client_payment.person_id_num,
        body: "#{client_payment.client.name} - #{client_payment.order_title}",
        notify_url: NOTIFY_URL,
        callback_url: CALLBACK_URL
        )
      mab, js, mac = get_mac(gw)
      gw.mac = mac
      gw.save

      ret_js = send_kaifu(js)
      client_payment.update(ret_js)
      gw.update(ret_js)
      ret_js
    end

    def get_mac(kf_data)
      js = []
      mab = ''
      OPENID_B001_FLDS.split(',').sort.each do |k|
        field_name = k.underscore
        mab << kf_data[field_name]
        js << "'#{k}':'#{kf_data[field_name]}'"
      end
      mab << TMK
      mac = Digest::MD5.hexdigest(mab)
      js << "'mac':'#{mac}'"
      [mab, "{#{js.join(',')}}", mac]
    end

    def send_kaifu(js)
      uri = URI(Biz::KaiFuApi::API_URL_OPENID)
      resp = Net::HTTP.post_form(uri, data: js)

      Rails.logger.info '------KaiFu D0 B001------'
      Rails.logger.info resp.to_s
      Rails.logger.info resp.to_hash

      if resp.is_a?(Net::HTTPRedirection)
        return {resp_code: '00', resp_desc: '交易成功', status: 8, redirect_url: resp['location']}
      elsif resp.is_a?(Net::HTTPOK)
        js = JSON.parse(resp.body)
      else
        js = {resp_code: '96', resp_desc: '系统故障', status: 7}
      end
    end
  end
end
