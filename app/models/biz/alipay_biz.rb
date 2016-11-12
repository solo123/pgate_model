require 'openssl'
require 'base64'

module Biz
  class AlipayBiz < BizBase
    def pay(payment)
    end
    def gen_response_json
    end

    def rsa_sign(key, string)
      rsa = OpenSSL::PKey::RSA.new(key)
      Base64.strict_encode64(rsa.sign('sha1', string))
    end

    def rsa_verify?(key, string, sign)
      rsa = OpenSSL::PKey::RSA.new(key)
      rsa.verify('sha1', Base64.strict_decode64(sign), string)
    end

    def get_mab(js)
      js.sort.map { |item| item.join('=') }.join('&')
    end
  end
end
