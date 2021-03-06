module Biz
  class TfbApi < BizBase
    FLDS_TFB_REQUEST = %W(spid notify_url pay_show_url sp_billno spbill_create_ip pay_type tran_time tran_amt cur_type item_name bank_mch_name bank_mch_id).freeze
    FLDS_TFB_REQUEST_ANSWER = %W(cur_type pay_type sp_billno spid tran_amt)

    def self.create_tfb_order(cp)
      ord = TfbOrder.new
      ord.spid = AppConfig.get('tfb.api.spid')
      ord.notify_url = AppConfig.get('tfb.api.notify_url')
      ord.pay_show_url = cp.callback_url
      ord.sp_billno = "T1" + ('%06d' % cp.id)
      ord.spbill_create_ip = cp.remote_ip
      ord.pay_type = '800206'
      ord.tran_time = cp.order_time
      ord.tran_amt = cp.amount
      ord.cur_type = 'CNY'
      ord.item_name = cp.order_title
      ord.bank_mch_name = cp.org_id
      ord.bank_mch_id = "%07d" % cp.id
      ord.status = 0
      ord.client_payment = cp
      ord.save!
      ord
    end

    #params: ord = tfb_order
    def self.send_tfb_order(ord)
      return if ord.status > 0

      url = AppConfig.get('tfb.api.pay_url')
      tmk = AppConfig.get('tfb.api.key')

      js = {}
      FLDS_TFB_REQUEST.each {|fld| js[fld] = ord[fld] if ord[fld]}
      mab = js.keys.sort.map{|k| "#{k}=#{js[k]}"}.join('&')
      ord.sign = js[:sign] = Biz::PubEncrypt.md5(mab + "&key=#{tmk}").upcase
      ord.input_charset = js[:input_charset] = 'UTF-8'
      ret = Biz::WebBiz.get_tfb(url, js, ord)

      if ret && (rt = ret['root'])
        ord.retcode = rt['retcode']
        ord.retmsg  = rt['retmsg']
        if rt['retcode'] == '00' && check_rt_equal(FLDS_TFB_REQUEST_ANSWER, ord, rt)
          ord.listid = rt['listid']
          ord.qrcode = rt['qrcode']
          ord.pay_info = URI.decode(rt['pay_info']) if rt['pay_info']
          ord.sysd_time = rt['sysd_time']

          ord.status = 1
        else
          ord.status = 7
        end
      else
      end
      ord.save!
    end

    #params: ord=tfb_order, rt=root of return hash
    def self.check_rt_equal(flds, ord, rt)
      msg = []
      flds.each do |fld|
        if rt[fld] != ord[fld].to_s
          msg << "#{fld}返回值不匹配: (#{ord[fld]}) != (#{rt[fld]})"
        end
      end
      if msg.length > 0
        err = BizError.new
        err.code = '96'
        err.message = "返回值不匹配"
        err.detail = msg.join(", ")
        err.error_source = ord
        err.save!
        false
      else
        true
      end
    end

    #params rev = recv_post
    def self.send_notify(rev)
      return unless rev.status == 0 && rev.method == 'tfb'

      js = eval(rev.params)
      js['retmsg'] = js['retmsg'].encode('UTF-8', 'GBK') if js['retmsg']
      js['item_name'] = js['item_name'].encode('UTF-8', 'GBK') if js['item_name']

      ord = TfbOrder.find_by(sp_billno: js['sp_billno'])
      if ord
        flds = %w(listid pay_type tran_amt)
        if check_rt_equal(flds, ord, js) && js['tran_state'] == '1'
          ord.status = 8
          ord.save!
          c = ord.client_payment
          c.status = 8
          c.pay_code = '00'
          c.pay_desc = '支付成功'
          c.save!

          rev.status = 8
        else
          rev.status = 7
          rev.message = 'tfb_order信息与回调值不匹配，或tran_state不对。'
        end
      else
        rev.status = 7
        rev.message = "tfb_order:[#{js['sp_billno']}]没找到！"
      end
      rev.save!
      ord
    end

    #params: ord = tfb_order
    def self.send_query(ord)
      url = AppConfig.get('tfb.api.query_url')
      tmk = AppConfig.get('tfb.api.key')
      js = {
        spid: ord.spid,
        listid: ord.listid
      }
      js[:sign] = js_mac(js, ord.client_payment.client.tmk)
      ret = Biz::WebBiz.get_tfb(url, js, ord)
      if ret && (rt = ret['root'])
        if rt['retcode'] == '00' && rt['spid'] == ord.spid
          if rt['record'] && rt['record']['listid'] == ord.listid
            ord.state = rt['record']['state']
            ord.pay_time = rt['record']['pay_time']
            ord.close_time = rt['record']['close_time']
            if ord.state == '3'
              ord.tran_state = '1'
              ord.status = 8
            end
            if ord.state == '4'
              ord.tran_state = '0'
              ord.status = 7
            end
            if ord.state == '5'
              ord.status = 7
            end
          end
        end
      else
      end
      ord.save!
    end

    def self.js_mac(js, tmk)
      mab = js.keys.sort.map{|k| "#{k}=#{js[k.to_sym]}"}.join('&')
      Biz::PubEncrypt.md5(mab + "&key=#{tmk}").upcase
    end
  end
end
