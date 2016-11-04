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

    def self.gen_js(fields, dt)
      js = {}
      fields.keys.each do |k|
        js[k.to_sym] = dt[k] if dt[k]
      end
      js
    end
    def self.parse_json(str)
      if str.nil? || str.empty? || !str.match( /{.+}/ )
        nil
      else
        begin
          js = JSON.parse(str).symbolize_keys
        rescue
          js = nil
        end
        js
      end
    end

  end
end
