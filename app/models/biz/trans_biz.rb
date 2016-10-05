module Biz
  class TransBiz
    def self.create_notify(recv_post)
      return nil if recv_post.status > 0

      case recv_post.remote_host
      when AppConfig.get('kaifu.host.notify')
        create_kaifu_notify(recv_post)
      when AppConfig.get('tfb.host.notify')
        create_tfb_notify
      end
    end
    def self.create_tfb_notify
      nil
    end
    def self.create_kaifu_notify(recv_post)
      notify = nil
      begin
        js = JSON.parse(recv_post.data)
        js = Biz::KaifuApi.js_to_app_format(js).symbolize_keys
        r = KaifuResult.new(js)
        r.sender = recv_post
        
        r.init_data
        if r.validate
          recv_post.status = 1
          recv_post.save!
          r.save!
          notify = Biz::TransBiz.process_kaifu_result(r)
        else
          recv_post.stauts = 7
          recv_post.message = "数据错：#{r.errors.messages.to_s}"
          recv_post.save!
        end
      rescue => e
        recv_post.message = "数据格式错！#{e.message}"
        #puts e.backtrace.join("\n")
        recv_post.status = 7
        recv_post.save!
      end
      notify
    end

    def self.process_kaifu_result(result)
      return nil if result.status > 0

      gw = KaifuGateway.find_by(send_seq_id: result.org_send_seq_id)
      unless gw
        result.message = 'send_seq_id not found in KaifuGateway!'
        result.status = 7
        result.save
        return nil
      end

      gw.pay_code = result.pay_result
      gw.pay_desc = result.pay_desc
      gw.t0_code  = result.t0_resp_code
      gw.t0_desc  = result.t0_resp_desc
      gw.status = 8
      gw.save

      pm = gw.client_payment
      unless pm
        result.message = 'client payment not found!'
        result.status = 7
        result.save
        return nil
      end
      result.client_payment = pm
      result.client = pm.client
      pm.pay_code = result.pay_result
      pm.pay_desc = result.pay_desc
      pm.t0_code = result.t0_resp_code
      pm.t0_desc = result.t0_resp_desc
      pm.save

      js = {
        org_id: result.organization_id,
        order_id: result.org_send_seq_id,
        pay_code: result.pay_result,
        pay_desc: result.pay_desc,
        t0_code: result.t0_resp_code,
        t0_desc: result.t0_resp_desc,
        amount: result.trans_amt.to_s,
        fee: result.fee.to_s
      }
      mab = Biz::PubEncrypt.get_mab(js)
      key = pm.client.tmk
      js[:mac] = Biz::PubEncrypt.md5(mab + key)

      result.status = 8
      result.save

      new_send_notify(js, pm.notify_url, result)
    end

    def self.new_send_notify(js, notify_url, sender)
      n = Notify.new
      n.sender = sender
      n.data = js.to_json.to_s
      n.notify_url = notify_url
      n.status = 0
      n.save
      n
    end


  end
end
