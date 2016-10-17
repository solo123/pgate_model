module Biz
  class PaymentBiz < BizBase
    def self.parse_data_json(data)
      js = {}
      if data.nil? || data.empty?
        return {resp_code: '30', resp_desc: '报文为空'}
      end
      if !data.match( /{.+}/ )
        return {resp_code: '30', resp_desc: '数据格式错误'}
      end
      begin
        js = JSON.parse(data.force_encoding('UTF-8')).symbolize_keys
      rescue => e
        return {resp_code: '30', resp_desc: '数据JSON格式错误，' + e.message}
      end

      required_fields = [:org_id, :trans_type, :mac]
      if !(miss_flds = required_fields.select{|f| js[f].nil? }).empty?
        return {resp_code: '30', resp_desc: '报文错，缺少字段：' + miss_flds.join(', ')}
      end

      client = Client.find_by(org_id: js[:org_id])
      if client.nil?
        return {resp_code: '03', resp_desc: "无此商户: #{js[:org_id]}"}
      end

      if js[:mac].upcase != get_client_mac(js)
        return {resp_code: 'A0', resp_desc: '检验mac错'}
      end
      js[:resp_code] = '00'
      js
    end

    def self.get_client_mac(js)
      if client = Client.find_by(org_id: js[:org_id])
        Digest::MD5.hexdigest(Biz::PubEncrypt.get_mab(js) + client.tmk).upcase
      else
        ''
      end
    end

    def self.update_json(record, js)
      fields = record.attributes.keys
      record.attributes = js.reject{|k,v| !fields.member?(k.to_s) }
    end

    #params c = client_payment
    def self.send_notify(c)
      notify_time = Time.now
      js = {
        org_id: c.org_id,
        trans_type: c.trans_type,
        order_time: c.order_time,
        order_id: c.order_id,
        amount: c.amount,
        attach_info: c.attach_info,
        resp_code: c.resp_code,
        resp_desc: c.resp_desc,
        pay_code: c.pay_code,
        pay_desc: c.pay_desc,
        notify_time: notify_time.strftime("%Y%m%d%H%M%S"),
        op_time: c.updated_at.strftime("%Y%m%d%H%M%S")
      }
      mab = Biz::PubEncrypt.get_mab(js)
      js[:mac] = Biz::PubEncrypt.md5(mab + c.client.tmk)
      txt = Biz::WebBiz.post_data(c.notify_url, js.to_json, c)
      c.notify_times += 1
      c.last_notify = notify_time
      c.notify_status = 8 if txt =~ /(true)|(ok)|(success)/
      c.save!
    end

    def self.pay_query(org_id, order_time, order_id)
      uid = "#{org_id}-#{order_time[0..7]}-#{order_id}"
      if cp = ClientPayment.find_by(uni_order_id: uid)
        fields = [:org_id, :trans_type, :order_time, :order_id, :order_title, :img_url, :amount, :fee, :card_no, :card_holder_name, :person_id_num, :notify_url, :callback_url, :mac, :created_at, :redirect_url, :pay_code, :pay_desc, :t0_code, :t0_desc, :remote_ip, :uni_order_id, :notify_times, :notify_status, :last_notify, :attach_info, :sp_udid, :pay_time, :close_time, :refund_id]
        js = db_2_json(fields, cp)
        js['resp_code'] = '00'
        js['mac'] = Biz::PubEncrypt.md5_mac(js, cp.client.tmk)
        js
      else
        {resp_code: '12', resp_desc: "无此交易: #{uid}"}
      end

    end

    def self.db_2_json(fields, db)
      js = {}
      fields.each do |fld|
        js[fld] = db[fld] if db[fld]
      end
      js
    end

  end
end
