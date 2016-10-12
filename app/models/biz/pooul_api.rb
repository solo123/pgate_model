module Biz
  class PooulApi < BizBase
    def self.payment(client_payment)
      chk_js = client_payment.check_payment_fields
      if chk_js[:resp_code] != '00'
        client_payment.status = 7
        client_payment.save
        return chk_js
      end

      client_payment.status = 1
      client_payment.save

      case client_payment.trans_type
      when 'P001', 'P002', 'P003', 'P004'
        kaifu_gateway = Biz::KaifuApi.create_kaifu_payment(client_payment)
        Biz::KaifuApi.send_kaifu(kaifu_gateway)
      when 'T001'
        c = client_payment
        ord = Biz::TfbApi.create_tfb_order(c)
        Biz::TfbApi.send_tfb_order(ord)
        update_client_payment(ord)
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
        c = ord.client_payment
        c.resp_code = ord.retcode
        c.resp_desc = ord.retmsg
        if ord.status == 1
          c.redirect_url = ord.pay_info
          c.status = 8
          c.save!
          js = {
            resp_code: '00',
            resp_desc: c.resp_desc,
            redirect_url: c.redirect_url,
            org_id: c.org_id,
            trans_type: c.trans_type,
            order_time: c.order_time,
            order_id: c.order_id,
            amount: c.amount,
            fee: c.fee
          }
          js
        else
          c.status = 7
          {resp_code: c.resp_code, resp_desc: c.resp_desc}
        end

      else
        {resp_code: '99', resp_desc: '无法更新商户交易数据。'}
      end
    end
  end
end
