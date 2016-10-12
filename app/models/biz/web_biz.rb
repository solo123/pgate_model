module Biz
  class WebBiz < BizBase
    def self.notify_client_test(kaifu_result)
      js = {
        org_id: kaifu_result.organization_id,
        order_id: kaifu_result.org_send_seq_id,
        pay_result: kaifu_result.pay_result,
        pay_desc: kaifu_result.pay_desc,
        amount: kaifu_result.trans_amt.to_s,
        fee: kaifu_result.fee.to_s
      }
      if kaifu_result.t0_resp_code == '00'
        js[:pay_desc] += ' T0:' + kaifu_result.t0_resp_desc
      end
      mab = Biz::PubEncrypt.get_mab(js)
      key = kaifu_result.client.tmk
      js[:mac] = Biz::PubEncrypt.md5(mab + key)
      puts '--------------'
      puts 'JSon:' + js.to_json
      puts 'mab: ' + mab
      puts 'key: ' + key
    end

    def self.post_data(url, data, sender)
      pd = PostDat.new
      pd.sender = sender
      pd.url = url
      pd.data = data

      txt = nil
      begin
        uri = URI(url)
        resp = Net::HTTP.post_form(uri, data: data)
        pd.response = resp.inspect
        if resp.is_a?(Net::HTTPOK)
          txt = pd.body = resp.body.force_encoding('UTF-8')
        elsif resp.is_a?(Net::HTTPRedirection)
          if resp['location'].nil?
            txt = resp.body.match(/<a href=\"([^>]+)\">/i)[1]
          else
            txt = resp['location']
          end
          pd.body = txt = '{"resp_code":"00","redirect_url":"' + txt + '"}'
        else
          err = BizError.new
          err.code = '96'
          err.message = "系统故障"
          err.detail = "not HTTPOK!\n" + resp.to_s + "\n" + resp.to_hash.to_s
          err.error_source = sender
          err.save!
        end
      rescue => e
        err = BizError.new
        err.code = '96'
        err.message = "系统故障"
        err.detail = "request error!\n#{e.message}"
        err.error_source = sender
        pd.error_message = e.message
        err.save
      end
      pd.save!
      txt
    end
    def redirect_url
    end
    def self.get_tfb(url, data, sender)
      pd = PostDat.new
      pd.sender = sender
      pd.url = url
      pd.data = data.to_s

      ret = nil
      begin
        uri = URI(url)
        #uri.query = URI.encode(data)
        uri.query = URI.encode_www_form(data)
        #puts "uri: " + uri.to_s
        resp = Net::HTTP.get_response(uri)
        pd.response = resp.inspect
        if resp.is_a?(Net::HTTPOK)
          body_txt = resp.body
          ret = Hash.from_xml(body_txt)
          pd.body = ret.to_s
        else
          err = BizError.new
          err.code = '96'
          err.message = "系统故障"
          err.detail = "not HTTPOK!\n" + resp.to_s + "\n" + resp.to_hash.to_s
          err.error_source = sender
          err.save!
        end
      rescue => e
        err = BizError.new
        err.code = '96'
        err.message = "系统故障"
        err.detail = "request error!\n#{e.message}\n#{body_txt}"
        err.error_source = sender
        err.save!
        pd.error_message = e.message
      end
      pd.save!
      ret
    end

  end
end
