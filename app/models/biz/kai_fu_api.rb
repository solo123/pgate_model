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
      js = {
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
      }
      js[:mac] = get_mac(js, client_payment.client.tmk)
      gw = KaifuGateway.new(js)
      gw.client_payment = client_payment
      gw.save

      ret_js = send_kaifu(js)
      client_payment.update(ret_js)
      gw.update(ret_js)
      ret_js
    end

    def get_mac(js, tmk)
      mab = ''
      js.keys.sort.each {|k| mab << js[k] }
      mab << tmk
      mac = Digest::MD5.hexdigest(mab)
      mac
    end

    def send_kaifu(js)
      uri = URI(Biz::KaiFuApi::API_URL_OPENID)
      resp = Net::HTTP.post_form(uri, data: js.to_h)

      Rails.logger.info '------KaiFu D0 B001------'
      Rails.logger.info 'data = ' + js.to_s
      Rails.logger.info 'resp = ' + resp.to_s
      Rails.logger.info 'resp = ' + resp.to_hash.to_s
      Rails.logger.info 'resp.body = ' + resp.body.to_s

      if resp.is_a?(Net::HTTPRedirection)
        j = {resp_code: '00', resp_desc: '交易成功', status: 8, redirect_url: resp['location']}
      elsif resp.is_a?(Net::HTTPOK)
        j = {resp_code: '99', resp_desc: resp.body.to_s}
      else
        j = {resp_code: '96', resp_desc: '系统故障', status: 7}
      end
      j
    end
  end
end
