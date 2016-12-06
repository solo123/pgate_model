class ZxContrInfoList < ApplicationRecord
  belongs_to :zx_mct, foreign_key: 'zx_mercht'
  def pay_typ_encd_enum
    {
      '支付宝：条码支付': '00010001',
      '支付宝：扫码支付': '00010002',
      '支付宝：无线支付': '00010003',
      '微信：公众号支付 JSAPI': '00020001',
      '微信：原生扫码支付 NATIVE': '00020002',
      '微信：APP支付 APP': '00020003',
      '微信：刷卡支付 MICROPAY': '00020004'
    }
  end
end
