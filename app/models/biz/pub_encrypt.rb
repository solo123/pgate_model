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

    def self.json_parse(str)
      if str.nil? || str.empty? || !str.match( /{.+}/ )
        {}
      else
        JSON.parse(str).symbolize_keys
      end
    end
    def self.get_mab(js)
      js.keys.sort.map{|k| (k != :mac && js[k]) ? js[k].to_s : nil }.join
    end
    def self.md5(str)
      Digest::MD5.hexdigest(str)
    end
    def self.get_mac(js, key)
      md5(get_mab(js) + key)
    end

    def self.brief_mask(str)
      if str && str.length > 8
        "#{str.first(4)}-XXX-#{str.last(4)}"
      else
        str
      end
    end
  end
end
