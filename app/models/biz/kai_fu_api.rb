module Biz
  class KaiFuApi
    ORG_ID = 'puerhanda'
    TMK = '9DB9095654D1FA7763F32E6B4E922140'
    API_URL_OPENID = 'http://61.135.202.242/payform/organization_ymf'
    NOTIFY_URL = 'http://112.74.184.236:8010/recv_notify'
    CALLBACK_URL = 'http://112.74.184.236:8010/recv_callback'
    OPENID_B001_FLDS = "sendTime,sendSeqId,transType,organizationId,payPass,transAmt,fee,cardNo,name,idNum,body,notifyUrl,callbackUrl"

    def fill_info_openid_d0(kf_data)
      pooul_data = kf_data.dup
      pooul_data.parent_id = kf_data.id
      pooul_data.send_time = Time.now.strftime("%Y%m%d%H%M%S")
      pooul_data.send_seq_id = "PL01" + ('%010d' % kf_data.id)
      pooul_data.trans_type = 'B001'
      pooul_data.organization_id = ORG_ID
      pooul_data.notify_url = NOTIFY_URL
      pooul_data.callback_url = CALLBACK_URL
      pooul_data.status = 0
      pooul_data
    end

    def get_mac(kf_data)
      js = []
      mab = ''
      OPENID_B001_FLDS.split(',').sort.each do |k|
        field_name = k.underscore
        mab << kf_data[field_name]
        js << "'#{k}':'#{kf_data[field_name]}'"
      end
      mab << TMK
      mac = Digest::MD5.hexdigest(mab)
      js << "'mac':'#{mac}'"
      [mab, "{#{js.join(',')}}", mac]
    end

  end
end
