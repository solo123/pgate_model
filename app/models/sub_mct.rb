class SubMct < ApplicationRecord
  belongs_to :org
  belongs_to :bank_mct, polymorphic: true
  def clearing_type_enum
    {'待定': 0, 'T1': 1, 'D0': 2}
  end

  def bank_mct_type_enum
    {"中信直连": 'ZxMct', '商联：合众易宝': 'hzyb'}
  end

  def pay_channel_type_enum
    {"微信": 0, "支付宝": 1}
  end

  def status_enum
    {"新商户(未发送)": 0, "已进件": 1, "有效商户": 8, "无效商户": 7}
  end

end
