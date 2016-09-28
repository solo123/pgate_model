module Biz
  class KaifuApi < BizBase
    def self.send_kaifu_payment(client_payment)
      case client_payment.trans_type
      when 'P001'
        create_b001(client_payment)
      when 'P002'
        create_b002(client_payment)
      when 'P003'
        create_b001(client_payment)
      when 'P004'
        create_b002(client_payment)
      else
        {resp_code: '12', resp_desc: "无此交易：#{client_payment.trans_type}"}
      end
    end
    def self.send_kaifu_query(payment_query)
      case payment_query.trans_type
      when 'Q001'
        create_q001(payment_query)
      else
        {resp_code: '12', resp_desc: "无此交易：#{q.trans_type}"}
      end
    end
    def self.create_b001(client_payment)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P1" + ('%06d' % client_payment.id),
        trans_type: 'B001',
        organization_id: AppConfig.get('kaifu.user.d0.org_id'),
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        card_no: client_payment.card_no,
        name: client_payment.card_holder_name,
        id_num: client_payment.person_id_num,
        body: client_payment.order_title,
        notify_url: AppConfig.get('pooul.api.notify_url'),
        callback_url: client_payment.callback_url
      }
      return create_kaifu_payment(client_payment, js)
    end
    def self.create_b002(client_payment)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P2" + ('%06d' % client_payment.id),
        trans_type: 'B002',
        organization_id: AppConfig.get('kaifu.user.t1.org_id'),
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        body: client_payment.order_title,
        notify_url: AppConfig.get('pooul.api.notify_url'),
        callback_url: client_payment.callback_url
      }
      return create_kaifu_payment(client_payment, js)
    end
    def self.create_q001(payment_query)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: 'QRY' + ('%06d' % payment_query.id),
        trans_type: 'B003'
      }
      return create_kaifu_query(payment_query, js)
=begin
      t.belongs_to :payment_query, index: true
      t.string :send_time
      t.string :send_seq_id
      t.string :trans_type
      t.string :organization_id
      t.string :org_send_seq_id
      t.string :trans_time
      t.string :pay_result
      t.string :pay_desc
      t.string :t0_pay_result
      t.string :t0_pay_desc
      t.string :resp_code
      t.string :resp_desc
      t.string :mac
      t.string :response_text
      t.timestamps
=end
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P1" + ('%06d' % client_payment.id),
        trans_type: 'B001',
        organization_id: AppConfig.get('kaifu.user.d0.org_id'),
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        card_no: client_payment.card_no,
        name: client_payment.card_holder_name,
        id_num: client_payment.person_id_num,
        body: client_payment.order_title,
        notify_url: AppConfig.get('pooul.api.notify_url'),
        callback_url: client_payment.callback_url
      }
      return create_kaifu_payment(client_payment, js)
    end

    def self.create_kaifu_payment(client_payment, js)
      kf_js = js_to_kaifu_format(js)
      mac = js[:mac] = kf_js["mac"] = get_mac(kf_js, client_payment.trans_type)
      gw = KaifuGateway.new(js)
      gw.client_payment = client_payment
      gw.save

      ret_js = send_kaifu(kf_js, client_payment.trans_type)
      ret_js[:status] = (ret_js[:resp_code] == '00') ? 8 : 7
      client_payment.attributes = {
        resp_code: ret_js[:resp_code],
        resp_desc: ret_js[:resp_desc],
        img_url: ret_js[:img_url]
      }
      gw.update(ret_js)
      ret_js
    end
    def self.create_kaifu_query(payment_query, js)
      unless kfp = payment_query.client_payment.kaifu_gateway
        return {resp_code: '13', resp_desc: '未找到该订单发送记录'}
      end
      js[:organization_id] = kfp.organization_id,
      js[:org_send_seq_id] = kfp.send_seq_id,
      js[:trans_time] = kfp.send_time[0..7]
      kf_js = js_to_kaifu_format(js)
      mac = js[:mac] = kf_js["mac"] = get_mac(kf_js, 'Q001')
      gw = KaifuQuery.new(js)
      gw.payment_query = payment_query
      gw.save

      ret_js = send_kaifu_query(kf_js, gw)
      ret_js[:status] = (ret_js[:resp_code] == '00') ? 8 : 7
      client_payment.attributes = {
        resp_code: ret_js[:resp_code],
        resp_desc: ret_js[:resp_desc],
        img_url: ret_js[:img_url]
      }
      gw.update(ret_js)
      ret_js
    end

    def self.get_mac(js, trans_type)
      mab = Biz::PubEncrypt.get_mab(js)
      case trans_type
      when 'P001'
        Biz::PubEncrypt.md5(mab + AppConfig.get('kaifu.user.d0.tmk'))
      when 'P002'
        Biz::PubEncrypt.md5(mab + AppConfig.get('kaifu.user.t1.tmk'))
      when 'P003'
        kaifu_mac(mab, AppConfig.get('kaifu.user.d0.skey'))
      when 'P004'
        kaifu_mac(mab, AppConfig.get('kaifu.user.t1.skey'))
      else
        ''
      end
    end

    def self.send_kaifu(js, trans_type)
      if trans_type == 'P001' || trans_type == 'P002'
        uri = URI(AppConfig.get('kaifu.api.openid.pay_url'))
      else
        uri = URI(AppConfig.get('kaifu.api.app.pay_url'))
      end
      resp = Net::HTTP.post_form(uri, data: js.to_json)
      if resp.is_a?(Net::HTTPRedirection)
        j = {resp_code: '00', resp_desc: '交易成功', redirect_url: resp['location']}
      elsif resp.is_a?(Net::HTTPOK)
        begin
          body_txt = resp.body.force_encoding('UTF-8')
          j = js_to_app_format(JSON.parse(body_txt)).symbolize_keys
          j[:resp_desc] = '[server] ' + j[:resp_desc]
        rescue => e
          j = {resp_code: '99', resp_desc: "ERROR: #{e.message}\n#{body_txt}"}
        end
      else
        j = {resp_code: '96', resp_desc: '系统故障:' + resp.to_s + "\n" + resp.to_hash.to_s}
      end
      j
    end
    def self.send_kaifu_query(js)
      uri = URI(AppConfig('kaifu.api.openid.query_url'))
      resp = Net::HTTP.post_form(uri, data: js.to_json)
      if resp.is_a?(Net::HTTPOK)
        begin
          body_txt = resp.body.force_encoding('UTF-8')
          r = js_to_app_format(JSON.parse(body_txt)).symbolize_keys
          gw.update(r)
          j = {
            resp_code: r[:resp_code],
            resp_desc: "#{r[:resp_desc]} #{r[:t0_resp_desc]}",
            pay_result: r[:pay_result],
            pay_desc: r[:pay_desc]
          }
          kfp = KaifuGateway.find_by(organizationId: r[:organization_id])
          cp = kfp.client_payment
          j[:order_id] = cp.order_id
          j[:order_time] = cp.order_time
        rescue => e
          j = {resp_code: '99', resp_desc: "ERROR: #{e.message}\n#{body_txt}"}
        end
      else
        j = {resp_code: '96', resp_desc: '系统故障:' + resp.to_s + "\n" + resp.to_hash.to_s}
      end
      j
    end

    def self.js_to_kaifu_format(js)
      Hash[js.map {|k,v| [k.to_s.camelize(:lower).to_sym, v]} ]
    end
    def self.js_to_app_format(js)
      Hash[js.map {|k,v| [k.to_s.underscore, v]} ]
    end

    def self.kaifu_mac(mab, key)
      mab = mab.encode('GBK')
      r = Biz::PosEncrypt.pos_mac(mab, key)
      r.unpack('H*')[0][0..7].upcase
    end

    def self.decrypt_signin_key(key, tmk)
      Biz::PosEncrypt.e_mak_decrypt([key].pack('H*'), tmk) \
        .unpack('H*')[0] \
        .upcase
    end

  end
end
