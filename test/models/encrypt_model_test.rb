require 'test_helper'

class EncryptModelTest < ActiveSupport::TestCase
  test "Mac test" do
    js = {a: '123', c: '456', b: 'abc', mac: 'lkl'}
    tmk = '000'
    assert_equal '123abc456000', Biz::PubEncrypt.json_tmk(js, tmk)
  end
end
