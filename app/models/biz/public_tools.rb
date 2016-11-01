module Biz
  class PublicTools < BizBase
    def self.update_fields_json(fields, db, js)
      db.attributes = js.reject{|k,v| !fields.member?(k.to_s) }
    end

    def self.get_mab(js)
      mab = []
      js.keys.sort.each do |k|
        mab << "#{k}=#{js[k].to_s}" if k != :mac && k != :sign && js[k]
      end
      mab.join('&')
    end
    def self.md5(str)
      Digest::MD5.hexdigest(str)
    end
    def self.get_mac(js, key)
      md5(get_mab(js) + key).upcase
    end

  end
end
