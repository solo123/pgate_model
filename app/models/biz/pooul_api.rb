module Biz
  class PooulApi < BizBase
    def self.payment(client_payment)
      case client_payment.trans_type
      when 'P001', 'P002', 'P003', 'P004'
        js = client_payment.check_fee
        if js[:resp_code] != '00'
          return js
        end
        kaifu_gateway = Biz::KaifuApi.create_kaifu_payment(client_payment)
        Biz::KaifuApi.send_kaifu(kaifu_gateway)
        update_client_payment(kaifu_gateway)
      when 'T001'
        c = client_payment
        ord = Biz::TfbApi.create_tfb_order(c)
        Biz::TfbApi.send_tfb_order(ord)
        update_client_payment(ord)
      when 'Q001'
        {resp_code: '99', resp_desc: 'PooulApi中查询方法尚未实现'}
      else
        {resp_code: '12', resp_desc: '无此交易：' + client_payment.trans_type.to_s}
      end
    end

    def self.update_client_payment(ord)
      if ord.is_a? TfbOrder
        tfb_order_2_client(ord)
        ord.client_payment.return_json
      elsif ord.is_a? KaifuGateway
        kaifu_gateway_2_client(ord)
        ord.client_payment.return_json
      else
        {resp_code: '99', resp_desc: '无法更新商户交易数据。'}
      end
    end

    #params: k = kaifu_gateway
    def self.kaifu_gateway_2_client(k)
      c = k.client_payment
      c.resp_code = k.resp_code
      c.resp_desc = k.resp_desc
      c.img_url = k.img_url
      c.redirect_url = k.redirect_url
      c.pay_code = k.pay_code
      c.pay_desc = k.pay_desc
      c.t0_code = k.t0_code
      c.t0_desc = k.t0_desc
      c.status = k.status
      c.save!
    end

    #params: ord = tfb_order
    def self.tfb_order_2_client(ord)
      c = ord.client_payment
      c.resp_code = ord.retcode
      c.resp_desc = ord.retmsg
      c.redirect_url = ord.pay_info
      c.status = ord.status
      c.save!
    end

    def self.get_mab(js)
      mab = []
      js.keys.sort.each do |k|
        mab << "#{k}=#{js[k].to_s}" if k != :mac && k != :sign && js[k]
      end
      mab.join('&')
    end
    def self.md5(str)
      Digest::MD5.hexdigest(str)
    end
    def self.get_mac(js, key)
      md5(get_mab(js) + "&key=#{key}").upcase
    end


  end
end
