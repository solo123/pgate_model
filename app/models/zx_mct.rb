class ZxMct < ApplicationRecord
  belongs_to :org
  has_many :zx_contr_info_lists, foreign_key: 'zx_mercht_id', :dependent => :destroy
  accepts_nested_attributes_for :zx_contr_info_lists, :allow_destroy => true

  def status_enum
    {'新中信商户': 0, '已发送': 1, '提交数据错误': 2, '已生效': 3, '已停用': 4 }
  end

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
