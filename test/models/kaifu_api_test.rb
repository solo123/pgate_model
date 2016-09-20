require 'test_helper'

class KaifuApiTest < ActiveSupport::TestCase
  test "B001 test" do
    Biz::KaiFuApi.any_instance.stubs(:send_kaifu).returns({resp_code: '00', status: 8, redirect_url: 'https://open.weixin.qq.com/mock'})
    payment = client_payments(:valid_one)
    payment.client = clients(:one)
    payment.save

    biz = Biz::KaiFuApi.new
    js = biz.create_b001(payment)
    assert_equal '00', js[:resp_code]

    p = ClientPayment.find(payment.id)
    assert_equal 8, p.status
    assert_equal '00', p.resp_code
  end

  test "send to Kaifu Gateway" do
    Biz::KaiFuApi.any_instance.stubs(:send_kaifu).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    l = Rails.logger
    l.level = :debug

    biz = Biz::KaiFuApi.new
    gw = kaifu_gateways(:jimmy_liang)

=begin
    mab, para_json, mac = biz.get_mac(gw)
    assert_match /^\{/, para_json
    l.info 'MAB: ' + mab
    l.info 'JSON: ' + para_json
    l.info 'MAC: ' + mac

    js = biz.send_kaifu(para_json)
    assert_match /^https:\/\/open.weixin.qq.com/, js[:redirect_url]
=end
  end

end
