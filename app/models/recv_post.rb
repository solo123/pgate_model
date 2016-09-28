class RecvPost < ApplicationRecord
  scope :show_order, -> {order('id desc')}
  scope :not_send, -> {where(status: 0)}
  has_one :kaifu_result

  def check_is_valid_notify
    return false if self.status > 0

    result = false
    biz = Biz::KaifuApi.new
    begin
      js_data = eval(self.params)
      js = biz.js_to_app_format(JSON.parse(js_data["data"])).symbolize_keys
      r = KaifuResult.new(js)
      self.status = 1
      self.save
      r.recv_post = self
      r.save
      result = true
    rescue => e
      self.header = "[数据格式错！#{e.message}]" + self.header.to_s
      self.status = 7
      self.save
    end
    result
  end
end
