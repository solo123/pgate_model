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

    def self.query(payment_query)
      cp = payment_query.client_payment
      case cp.status
      when 0
        payment_query.pay_code = '12'
        payment_query.pay_desc = '无此交易(交易未能成功送出)'
      when 1
        #尚未收到交易成功信息
        kq = Biz::KaifuApi.create_kaifu_query(payment_query)
        if kq
          js = Biz::KaifuApi.send_kaifu_query(kq)
          if js[:resp_code] == '00'
            kq.resp_code = payment_query.resp_code = js[:resp_code]
            kq.resp_desc = payment_query.resp_desc = js[:resp_desc]
            kq.pay_code = payment_query.pay_code = js[:pay_result]
            kq.pay_desc = payment_query.pay_desc = js[:pay_desc]
            kq.t0_code  = payment_query.t0_code = js[:t0_resp_code]
            kq.t0_desc  = payment_query.t0_desc = js[:t0_resp_desc]
            if js[:pay_result] == '00'
              kq.status = 8
            end
            kq.save!
          end
        end
      when 7, 8
        payment_query.pay_code = cp.pay_code
        payment_query.pay_desc = cp.pay_desc
        payment_query.t0_code = cp.t0_code
        payment_query.t0_desc = cp.t0_desc
      end
      payment_query.save!
      js = JSON.parse(payment_query.to_json)
      js[:resp_code] = '00'
      js[:resp_desc] = ''
      js.delete("client_payment_id")
      js.delete("client_id")
      js.symbolize_keys
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

  end
end
