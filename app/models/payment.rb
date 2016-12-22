class Payment < ApplicationRecord
  belongs_to :req_recv
  belongs_to :card, optional: true
  belongs_to :org, optional: true
  has_one :pay_result
  has_many :sent_posts, as: :sender

  def status_enum
    {'已完成': 8, '已发送': 1, '支付失败': 7 }
  end
end
