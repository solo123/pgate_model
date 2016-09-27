module Biz
  class WebBiz < BizBase
    def notify_client(kaifu_result)
      kaifu_result.init_validate
      if kaifu_result.status < 7
        kaifu_result.status += 1
        kaifu_result.notify_time = Time.now
        begin
          uri = URI(kaifu_result.notify_url)
          js = {
            org_id: kaifu_result.organization_id,
            order_id: kaifu_result.org_send_seq_id,
            resp_code: kaifu_result.resp_code,
            resp_desc: kaifu_result.resp_desc,
            pay_result: kaifu_result.pay_result,
            pay_desc: kaifu_result.pay_desc,
            amount: kaifu_result.trans_amt,
            fee: kaifu_result.fee
          }
          if kaifu_result.t0_resp_code == '00'
            js[:pay_desc] += ' T0:' + kaifu_result.t0_resp_desc
          end
          kf_biz = Biz::KaifuApi.new
          mab = kf_biz.get_mab(js)
          key = kaifu_result.client.tmk
          js[:mac] = Digest::MD5.hexdigest(mab + key)
          resp = Net::HTTP.post_form(uri, data: js.to_json)
          if resp.is_a?(Net::HTTPOK)
            kaifu_result.status = 8
          end
        rescue => e
        end
        kaifu_result.save
      end
    end
    def notify_client_test(kaifu_result)
      js = {
        org_id: kaifu_result.organization_id,
        order_id: kaifu_result.org_send_seq_id,
        resp_code: kaifu_result.resp_code,
        resp_desc: kaifu_result.resp_desc,
        pay_result: kaifu_result.pay_result,
        pay_desc: kaifu_result.pay_desc,
        amount: kaifu_result.trans_amt,
        fee: kaifu_result.fee
      }
      if kaifu_result.t0_resp_code == '00'
        js[:pay_desc] += ' T0:' + kaifu_result.t0_resp_desc
      end
      kf_biz = Biz::KaifuApi.new
      mab = kf_biz.get_mab(js)
      key = kaifu_result.client.tmk
      js[:mac] = Digest::MD5.hexdigest(mab + key)
      puts '--------------'
      puts 'JSon:' + js.to_json
      puts 'mab: ' + mab
      puts 'key: ' + key
    end

  end
end
