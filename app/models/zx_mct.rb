class ZxMct < ApplicationRecord
  belongs_to :org
  has_many :zx_contr_info_lists, foreign_key: 'zx_mercht_id'
  
  def is_nt_citic_enum
    {'是': '1', '否': '0'}
  end
  def pay_chnl_encd_enum
    {'支付宝': '0001', '微信支付': '0002'}
  end
  def acct_typ_enum
    {'中信银行对私账户': '1', '中信银行对公账户': '2'}
  end
  def is_nt_two_line_enum
    {'是': '1', '否': '0'}
  end
  def appl_typ_enum
    {'新增': '0', '变更': '1', '停用': '2'}
  end
end