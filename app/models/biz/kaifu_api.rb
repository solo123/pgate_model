module Biz
  class KaifuApi < BizBase
    FLDS_KAIFU_OPENID_B001 = %W(send_time send_seq_id trans_type organization_id pay_pass trans_amt fee body notify_url callback_url card_no name id_num).freeze
    FLDS_KAIFU_OPENID_B002 = %W(send_time send_seq_id trans_type organization_id pay_pass trans_amt fee body notify_url callback_url).freeze
    FLDS_KAIFU_QUERY = %W(send_time send_seq_id trans_type organization_id org_send_seq_id trans_time).freeze

    def self.create_kaifu_payment(cp)
      gw = KaifuGateway.new
      gw.send_time = Time.now.strftime("%Y%m%d%H%M%S")
      gw.send_seq_id = "P1" + ('%06d' % cp.id)
      gw.trans_type = get_kaifu_trans_type(cp.trans_type)
      gw.organization_id = AppConfig.get('kaifu.user.d0.org_id')
      gw.pay_pass = cp.pay_pass
      gw.trans_amt = cp.amount.to_s
      gw.fee = cp.fee.to_s
      gw.card_no = cp.card_no
      gw.name = cp.card_holder_name
      gw.id_num = cp.person_id_num
      gw.body = cp.order_title
      gw.notify_url = AppConfig.get('pooul.api.notify_url')
      gw.callback_url = cp.callback_url
      gw.client_payment = cp
      gw.status = 0
      gw.mac = Biz::KaifuApi.get_mac(gw)
      gw.save
      gw
    end

    #para: kaifu_gateway
    def self.send_kaifu(k)
      return if k.status > 0
      if k.trans_type == 'B001'
        url = AppConfig.get('kaifu.api.openid.pay_url')
      else
        url = AppConfig.get('kaifu.api.app.pay_url')
      end
      resp = Biz::WebBiz.post_data(url, get_data(k, FLDS_KAIFU_OPENID_B001) , k)
      if resp
        js = js_to_app_format resp
        k.resp_code = js['resp_code']
        k.resp_desc = js['resp_desc']
        if js['resp_code'] == '00'
          k.redirect_url = js['redirect_url']
          k.img_url = js['img_url']
          k.status = 1
        end
        k.save!
      end
    end

    # params: p = payment_query
    def self.create_kaifu_query(p)
      unless kfp = p.client_payment.kaifu_gateway
        p.resp_code = '13'
        p.resp_desc = '未找到该订单发送记录'
        p.save!
        return nil
      end
      gw = KaifuQuery.new
      gw.send_time = Time.now.strftime("%Y%m%d%H%M%S")
      gw.send_seq_id = 'QRY' + ('%06d' % p.id)
      gw.trans_type = 'B003'
      gw.organization_id = kfp.organization_id
      gw.org_send_seq_id = kfp.send_seq_id
      gw.trans_time = kfp.send_time[0..7]
      gw.payment_query = p
      gw.mac = Biz::KaifuApi.qry_get_mac(gw)
      gw.save!
      return gw
    end
    def self.send_kaifu_query(payment_query)
      case payment_query.trans_type
      when 'Q001'
        create_q001(payment_query)
      else
        {resp_code: '12', resp_desc: "无此交易：#{q.trans_type}"}
      end
    end

    #params: k = kaifu_gateway
    def self.get_mac(k)
      return nil unless k.client_payment

      case k.client_payment.trans_type
      when 'P001'
        key = AppConfig.get('kaifu.user.d0.tmk')
        Biz::PubEncrypt.md5(get_mab(k, FLDS_KAIFU_OPENID_B001) + key)
      when 'P002'
        key = AppConfig.get('kaifu.user.t1.tmk')
        Biz::PubEncrypt.md5(get_mab(k, FLDS_KAIFU_OPENID_B002) + key)
      when 'P003'
        kaifu_mac(get_mab(k, FLDS_KAIFU_APP_B001), AppConfig.get('kaifu.user.d0.skey'))
      when 'P004'
        kaifu_mac(get_mab(k, FLDS_KAIFU_APP_B002), AppConfig.get('kaifu.user.t1.skey'))
      else
        nil
      end
    end
    #params: k = kaifu_query
    def self.qry_get_mac(k)
      Biz::PubEncrypt.md5(get_mab(k, FLDS_KAIFU_QUERY) + AppConfig.get('kaifu.user.d0.tmk'))
    end
    def self.get_mab(k, flds)
      flds.sort.map{|fld| k[fld]}.join
    end

    def self.get_data(k, flds)
      fs = flds.dup
      fs << "mac" unless flds.include?("mac")
      d = fs.map{|f| "\"#{f.camelize(:lower)}\":\"#{k[f].to_s}\""}.join(',')
      "{#{d}}"
    end
    def self.send_kaifu_query(kaifu_query)
      fields = %W(send_time send_seq_id trans_type organization_id org_send_seq_id trans_time mac)
      js = get_js_from_db(kqifu_query, fields)
      js = js_to_kaifu_format(js)
      uri = URI(AppConfig('kaifu.api.openid.query_url'))
      resp = Net::HTTP.post_form(uri, data: js.to_json)
      if resp.is_a?(Net::HTTPOK)
        begin
          body_txt = resp.body.force_encoding('UTF-8')
          j = js_to_app_format(JSON.parse(body_txt)).symbolize_keys
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
    def self.get_js_from_db(db_record, fields)
      js = {}
      fields.each do |f|
        js[f.to_sym] = db_record[f]
      end
      js
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

    def self.get_kaifu_trans_type(pooul_trans_type)
      case pooul_trans_type
      when 'P001'
        'B001'
      when 'P002'
        'B002'
      when 'Q001'
        'B003'
      else
        ''
      end
    end

  end
end
