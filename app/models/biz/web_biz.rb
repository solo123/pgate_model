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

  end
end
