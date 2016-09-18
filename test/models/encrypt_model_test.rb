require 'test_helper'

class EncryptModelTest < ActiveSupport::TestCase
  test "Mac test" do
    biz = Biz::PubEncrypt.new
    js = {a: '123', c: '456', b: 'abc', mac: 'lkl'}
    tmk = '000'
    assert_equal '123abc456000', biz.json_tmk(js, tmk)
  end
end
