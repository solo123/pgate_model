require 'test_helper'

class KaifuApiTest < ActiveSupport::TestCase
  test "B001 test" do
    payment = client_payments(:valid_one)
    payment.client = clients(:one)
    payment.save

    biz = Biz::KaiFuApi.new
    gw = biz.create_b001(payment)

    assert gw.is_a? (KaifuGateway)
    assert_equal payment.id, gw.client_payment_id

    assert_equal '00', gw.resp_code
  end

end
