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
        resp_code: c.resp_code,
        resp_desc: c.resp_desc,
        pay_code: c.pay_code,
        pay_desc: c.pay_desc,
        amount: c.amount,
        notify_time: notify_time.strftime("%Y%m%d%H%M%S")
      }
      mab = Biz::PubEncrypt.get_mab(js)
      js[:mac] = Biz::PubEncrypt.md5(mab + c.client.tmk)
      txt = Biz::WebBiz.post_data(c.notify_url, js.to_s, c)
      c.notify_times += 1
      c.last_notify = notify_time
      c.notify_status = 8 if txt =~ /(true)|(ok)|(success)/
      c.save!
    end

  end
end
