module Biz
  class WebBiz < BizBase
    def self.post_data(method, url, data, sender)
      pd = SentPost.new
      pd.method = method
      pd.sender = sender
      pd.post_url = url
      pd.post_data = data.truncate(2000, omission: '... (to long)')

      begin
        uri = URI(url)
        resp = Net::HTTP.post_form(uri, data)
        pd.resp_type = resp.inspect
        if resp.is_a?(Net::HTTPOK)
          pd.resp_body = resp.body.force_encoding('utf-8')
        elsif resp.is_a?(Net::HTTPRedirection)
          if resp['location'].nil?
            pd.resp_body = resp.body.match(/<a href=\"([^>]+)\">/i)[1]
          else
            pd.resp_body = resp['location']
          end
          pd.resp_body = "redirect_url:" + pd.resp_body
        else
          pd.result_message = "not HTTPOK!\n" + resp.to_s + "\n" + resp.to_hash.to_s
        end
      rescue => e
        pd.result_message = "request error!\n#{e.message}"
      end
      pd.save!
      pd
    end

  end
end
