module Biz
  class PubEncrypt
    def json_tmk(js, tmk)
      s = []
      js.keys.sort.each do |k|
        v = js[k]
        s << v if k.to_s.upcase != 'MAC' && v.length > 0
      end
      s << tmk
      s.join
    end

    def md5_mac(js, tmk)
      mab = ''
      js.keys.sort.each { |k| mab << js[k] if k != 'mac' }
      Digest::MD5.hexdigest(mab + tmk)
    end

    def xor_8(input_string)
      bs = input_string.bytes
      result_block = []
      (0..7).each do |i|
        result_block << cal_xor(bs, i)
      end
      result_block.pack('C*')
    end
    def cal_xor(arr, idx)
      len = arr.length
      i = idx
      r = 0
      while i < len do
        r = r ^ arr[i]
        i += 8
      end
      r
    end

  end
end
