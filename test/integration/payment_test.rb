require 'test_helper'

class PaymentTest < ActionDispatch::IntegrationTest
  test "payment test valid" do
    return
    Biz::WebBiz.stubs(:post_data).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    cp = client_payments(:valid_one)
    ret = Biz::PooulApi.payment(cp)
    assert ret
  end
end
