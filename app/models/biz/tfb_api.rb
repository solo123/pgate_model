module Biz
  class TfbApi < BizBase
    FLDS_TFB_REQUEST = %W(spid notify_url pay_show_url sp_billno spbill_create_ip pay_type tran_time tran_amt cur_type item_name bank_mch_name bank_mch_id).freeze
    FLDS_TFB_REQUEST_ANSWER = %W(cur_type pay_type sp_billno spid tran_amt)

    #params: ord = tfb_order
    def self.send_tfb_order(ord)
      return if ord.status > 0

      url = "http://apitest.tfb8.com/cgi-bin/v2.0/api_wx_pay_apply.cgi"
      user_id = '1800314099'
      tmk = '12345'

      js = {}
      FLDS_TFB_REQUEST.each {|fld| js[fld] = ord[fld] if ord[fld]}
      mab = js.keys.sort.map{|k| "#{k}=#{js[k]}"}.join('&')
      js[:sign] = Biz::PubEncrypt.md5(mab + "&key=#{tmk}").upcase
      js[:input_charset] = 'UTF-8'
      ret = Biz::WebBiz.get_tfb(url, js, ord)

      if ret && (rt = ret['root'])
        ord.retcode = rt['retcode']
        ord.retmsg  = rt['retmsg']
        if rt['retcode'] == '00' && check_rt_equal(FLDS_TFB_REQUEST_ANSWER, ord, rt)
          ord.listid = rt['listid']
          ord.qrcode = rt['qrcode']
          ord.pay_info = rt['pay_info']
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

  end
end
