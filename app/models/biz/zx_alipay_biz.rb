module Biz
  class ZxAlipayBiz < AlipayBiz
    def channel_name
      'zx_alipay'
    end
    def pay(payment)
      @p = payment
      case payment.method
      when 'alipay.trade.precreate'
        pay_precreate(payment)
      else
        @err_code = '20'
        @err_desc = "无此交易: #{payment.method}"
      end
    end
    def gen_response_json
      if @err_code == '00'
        {resp_code: '00', order_num: @p.order_num, qr_code: @p.pay_result.qr_code}.to_json
      else
        {resp_code: @err_code, resp_desc: @err_desc}.to_json
      end
    end

    def pay_precreate(payment)
      #TODO: config url, app_id, app_auth_token, & certs
      url = 'https://openapi.alipaydev.com/gateway.do'
      app_id = '2016072900117068'
      pay_result = payment.pay_result || payment.build_pay_result
      pay_result.uni_order_num = "PUL-#{payment.id.to_s.rjust(8, '0')}"
      pay_result.send_time = Time.now
      pay_result.channel_name = channel_name

      js_biz = {
        out_trade_no: pay_result.uni_order_num,
        total_amount: (payment.amount / 100.0).to_s,
        subject: payment.order_title
      }
      params = {
        app_id: app_id,
        method: 'alipay.trade.precreate',
        sign_type: 'RSA',
        charset: 'UTF-8',
        timestamp: Time.now.to_s[0..18],
        version: '1.0',
        notify_url: 'http://112.74.184.236:8008/notify/test_alipay',
        #app_auth_token: '201611BB381c6d470b204e85bfb4994a25aa6X22',
        biz_content: js_biz.to_json
      }

      mab = AlipayBiz.get_mab(params)
      key_path = AppConfig.get('pooul', 'keys_path')
      sign = AlipayBiz.rsa_sign(File.read("#{key_path}/pooul_rsa_private.pem"), mab)
      params[:sign] = sign
      pd = WebBiz.post_data(payment.method, url, params, payment)
      js_ret = PublicTools.parse_json(pd.resp_body)
      if js_ret
        js_rep = js_ret[:alipay_trade_precreate_response]
        if js_rep && js_rep['code'] == '10000' && (js_rep['out_trade_no'] == '...' || js_rep['out_trade_no'] == pay_result.uni_order_num)
          pay_result.qr_code = js_rep['qr_code']
          pay_result.send_code = '00'
          @err_code = '00'
        else
          @err_code = pay_result.send_code = '20'
          @err_desc = pay_result.send_desc =  js_rep.to_json
        end
      else
        @err_code = pay_result.send_code = '21'
        @err_desc = pay_result.send_desc = '通道连接错'
      end
      pay_result.save!
    end

  end
end
