module Biz
  class TfbApi < BizBase
    FLDS_TFB_REQUEST = %W(spid notify_url pay_show_url sp_billno spbill_create_ip pay_type tran_time tran_amt cur_type item_name bank_mch_name bank_mch_id).freeze

  end
end
