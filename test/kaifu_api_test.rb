require 'test_helper'

class KaifuApiTest < ActiveSupport::TestCase
  test "fixture data ok" do
    p = client_payments(:valid_one)
    k = kaifu_gateways(:jimmy_liang)
  end
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

  test "send to Kaifu Gateway" do
    l = Rails.logger
    l.level = :debug

    biz = Biz::KaiFuApi.new
    gw = kaifu_gateways(:jimmy_liang)

    mab, para_json, mac = biz.get_mac(gw)
    assert_match /^\{/, para_json
    l.info 'MAB: ' + mab
    l.info 'JSON: ' + para_json
    l.info 'MAC: ' + mac

    js = biz.send_kaifu(para_json)
    assert_match /^https:\/\/open.weixin.qq.com/, js['location']
  end

end
