require 'test_helper'

class TfbSendRequestTest < ActiveSupport::TestCase
  test "send tfb invalid request" do
    js = {"root"=>{"retcode"=>"205216", "retmsg"=>"商户号参数错误", "tid"=>"api_wx_pay_apply"}}
    rt = js['root']
    Biz::WebBiz.stubs(:get_tfb).returns(js)

    ord = tfb_orders(:ord_1)
    Biz::TfbApi.send_tfb_order(ord)
    assert_equal rt['retcode'], ord.retcode
    assert_equal 7, ord.status
  end
  test "send tfb valid request" do
    js = {"root"=>{"cur_type"=>"CNY", "listid"=>"1021800314099161012000020661", "pay_info"=>"https%3A%2F%2Fpay.swiftpass.cn%2Fpay%2Fwappay%3Ftoken_id%3D91079346142fdcbfc0d0be8aae906f77%26service%3Dpay.weixin.wappay", "pay_type"=>"800206", "retcode"=>"00", "retmsg"=>"操作成功", "sign"=>"287696d6bf93f94edae1dfdcd93c50f4", "sp_billno"=>"ORD1476239835", "spid"=>"1800314099", "sysd_time"=>"20161012103718", "tran_amt"=>"100"}}
    rt = js['root']
    Biz::WebBiz.stubs(:get_tfb).returns(js)

    ord = tfb_orders(:ord_1)
    Biz::TfbApi.send_tfb_order(ord)
    assert_equal '00', ord.retcode
    assert_equal 7, ord.status

    err = ord.biz_errors.last
    assert err
    assert_equal '返回值不匹配', err.message
  end
  test "send tfb success request" do
    js = {"root"=>{"cur_type"=>"CNY", "listid"=>"1021800314099161012000020661", "pay_info"=>"https%3A%2F%2Fpay.swiftpass.cn%2Fpay%2Fwappay%3Ftoken_id%3D91079346142fdcbfc0d0be8aae906f77%26service%3Dpay.weixin.wappay", "pay_type"=>"800206", "retcode"=>"00", "retmsg"=>"操作成功", "sign"=>"287696d6bf93f94edae1dfdcd93c50f4", "sp_billno"=>"ord-001", "spid"=>"1234", "sysd_time"=>"20161012103718", "tran_amt"=>"1000"}}
    rt = js['root']
    Biz::WebBiz.stubs(:get_tfb).returns(js)

    ord = tfb_orders(:ord_1)
    Biz::TfbApi.send_tfb_order(ord)
    assert_equal '00', ord.retcode
    assert_equal 1, ord.status
    assert_equal rt['listid'], ord.listid
    assert_equal rt['pay_info'], ord.pay_info
    assert_equal rt['sysd_time'], ord.sysd_time
  end

end
