# coding: UTF-8

require 'twivi'
require 'json'

module Twivi
class Worker

  def initialize( data_manager, credentials_json )
    client_credentials = credentials_json['client_credentials']
    user_credentials   = credentials_json['user_credentials'  ]
    # OAuthSimple::HTTP is a subclass of Net::HTTP
    @http_class = OAuthSimple::HTTP.create_subclass_with_default_oauth_params()
    @http_class.set_default_oauth_client_credentials( *client_credentials )
    @http_class.set_default_oauth_user_credentials( *user_credentials )
    @http_class.set_default_oauth_signature_method( 'HMAC-SHA1' )

    # UserStreams から受け取った文字列を一時的に格納しておくためのバッファ
    @buf = ''

    @data_manager = data_manager
    @going_to_end = false
    host = 'userstream.twitter.com'
    path = '/2/user.json'
    http = @http_class.new( host, 443)
    http.use_ssl = true
    #http.ca_file = 'GTE_CyberTrust_Global_Root.pem'
    http.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    http.verify_depth = 5
    @t = Thread.new do
      begin
        http.start() do |http|
          # TODO 外からの中止
          http.request_get( path ) do |res|
            # TODO res.code 200 のチェック
            if res.code != '200'
              Twivi.debug res.body
              break
            end
            res.read_body do |dat|
              break if @going_to_end
              @buf << dat
              proc_buf()
            end
            break
          end
        end
        #while true
        #  sleep 0.5
        #  break if @going_to_end
        #  @data_manager.add_status( Status.new( Time.now.to_s ) )
        #end
      rescue => err
        p err
        p err.backtrace
      end
    end
  end
  def finalize
    @going_to_end = true
    @t.wakeup
  end

  def proc_buf
    ss = @buf.split( "\r", -1 )
    @buf = ss.pop || ''
    ss.each do |s|
      next if /\A\s*\z/ =~ s
      json = JSON.parse( s )
      if json['text'] and json['user'] and json['user']['screen_name']
        @data_manager.add_status( Status.new( '@' + json['user']['screen_name'] + ': ' + json['text'] ) )
      else
        @data_manager.add_status( Status.new( '[処理できないデータ]' ) )
      end
    end
  end

end
end
