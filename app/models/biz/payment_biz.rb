module Biz
  class PaymentBiz < BizBase
    def self.parse_data_json(data)
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
        Digest::MD5.hexdigest(get_mab(js) + client.tmk).upcase
      else
        ''
      end
    end
    def self.get_mab(js)
      js.keys.sort.map{|k| (k != :mac && js[k]) ? js[k].to_s : nil }.join
    end

  end
end
