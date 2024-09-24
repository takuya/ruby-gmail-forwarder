RSpec.describe 'プロキシ・サーバーを起動してメールを送信する' do
  ## OAUTH2に必要なデータ
  $client_secret_path = ENV['client_secret_path']
  $token_path         = ENV['token_path']
  $user_id            = ENV['user_id']
  ##
  Thread.abort_on_exception=true

  it "init proxy server and send mail, then check mail by by xoauth IMAP." do
    log_level = 4 # 0:DEBUG, 3:ERROR @see Logger
    $uuid = SecureRandom.uuid
    $host_ip = "127.0.25.25"
    $host_port = rand(49151...65535)

    $proxy_process_called = false
    class MyTestServer < Takuya::GMailForwarderServer
      def on_message_received(envelope_from,envelope_to,received_message)
        proxy_smtp_sendmail(envelope_from, envelope_to, received_message)
        $proxy_process_called = true
      end

    end
    $server = MyTestServer.new(hosts:$host_ip,ports:$host_port,
    user_id: $user_id, client_secret_path: $client_secret_path, token_path: $token_path,logger_severity:log_level)


    def start_server
      ## no join, keep running in a thread.
      $server.start
      puts "server started smtp://#{$host_ip}:#{$host_port}"
    end

    def stop_server
      until $proxy_process_called
        sleep 1
      end
      puts "stopping sever..."
      $server.stop
      until $server.stopped? do
        sleep 0.3
        puts "stopped=#{$server.stopped?}"
      end
      puts "stopped=#{$server.stopped?}"
    end

    def sendmail_from_proxy
      require 'net/smtp'
      require 'mail'
      require 'base64'


      mail = Mail.new
      mail.delivery_method(:smtp, address: $host_ip, port: $host_port)
      mail.from = $user_id
      mail.to = $user_id
      mail.subject = "Test Mail from proxy #{Date.today.strftime('%Y-%m-%d')} / #{$uuid}"
      mail.body = "This is test from proxy/smtp-mini-server. from #{$host_ip}:#{$host_port}. "
      mail.date = Time.now
      mail.mime_version = '1.0'
      # #送信
      mail.deliver!
    end
    def check_mail_received
      imap = Takuya::XOAuth2::GMailXOAuth2.imap($client_secret_path, $token_path, $user_id)
      imap.select('INBOX')
      query = ['SUBJECT', $uuid, 'FROM', $user_id, 'TO', $user_id]
      message_ids = imap.search(query)
      message_ids.each do |m_id|
        imap.store(m_id, "+FLAGS", [:Seen])
        imap.store(m_id, "+FLAGS", [:Deleted])
      end

      response = imap.close
      response.name == 'OK' && message_ids.size > 0
    end

    def main
      start_server
      sendmail_from_proxy
      stop_server
      check_mail_received
    end

    result = nil
    expect { result = main }.not_to raise_error
    expect(result).to be true

  end

end