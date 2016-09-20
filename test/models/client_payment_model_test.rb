require 'test_helper'

class ClientPaymentModelTest < ActiveSupport::TestCase
  test "reqired params" do
    biz = Biz::GatewayPaymentBiz.new

    js = biz.check_required_params({a: '123'})
    assert_equal '30', js[:resp_code]

    js = biz.check_required_params({org_id: '123_999a', trans_type: 'abc', mac: 'mac'})
    assert_equal '03', js[:resp_code]

    js = biz.check_required_params({org_id: 'client1', trans_type: 'abc', mac: 'mac'})
    assert_equal 'A0', js[:resp_code]

    tmk = Client.find_by(org_id: 'client1').tmk
    mac = Digest::MD5.hexdigest('client1abc' + tmk)
    js = biz.check_required_params({org_id: 'client1', trans_type: 'abc', mac: mac})
    assert_equal 'A0', js[:resp_code]
  end
  test "check payment fields" do
    payment = client_payments(:invalid_fields_01)
    js = payment.check_payment_fields
    assert_equal '12', js[:resp_code]

    payment = client_payments(:valid_one)
    js = payment.check_payment_fields
    assert_equal '00', js[:resp_code]
  end
end
