require 'faraday/restrict_ip_addresses'

module MemeCaptainWeb
  # URL content fetcher.
  class UrlGetter
    def get(url)
      conn.get(url).body
    end

    private

    def conn
      Faraday.new do |c|
        c.use FaradayMiddleware::FollowRedirects
        c.use Faraday::Response::RaiseError
        c.use Faraday::RestrictIPAddresses, deny_rfc6890: true

        c.adapter Faraday.default_adapter
        c.ssl.verify = false
      end
    end
  end
end
