## SMTP to GMail Forwarder 

The PROXY-SMTP server relay to GMAIL-SMTP. This intended run as server.

## Installing

```sh
##  Gemfile initialized
bundle init
## add dependency
DEP_URL=https://github.com/takuya/ruby-google-xoauth2.git
echo gem "'takuya-xoauth2', git: '$DEP_URL'" >> Gemfile
## add this repository
REPO_URL=https://github.com/takuya/ruby-gmail-forwarder.git
echo "gem 'takuya-gmail-forwarder', git: '$REPO_URL'" >> Gemfile
## installation
bundle install 
```
### prepare credentials 

```sh
touch credentials/tokens.yml
touch credentials/client_secret.json
```

- client_secret.json / from Google Consle 
- tokens.yaml / from Google::Auth::Stores::FileTokenStore

to generate theese file , see [takuya-xoauth](https://github.com/takuya/ruby-google-xoauth2)

### Starting demo-server
```sh
bundle exec bin/smtp-proxy-debug.rb
```
### Starting sever

call `Smtpd#start` and `Smtpd#join` for waiting .
```ruby
def parepare_server
  require 'dotenv/load'
  Dotenv.load('.env', '.env.sample')
  user_id = YAML.load_file(ENV["token_path"]).keys[0]
  host = '127.0.25.25' 
  port = '2525' # rand(49151...65535)
  Takuya::GMailForwarderServer.new(
    user_id: user_id,
    token_path: ENV['token_path'],
    client_secret_path: ENV['client_secret_path'],
    hosts: host,
    ports: port
  )
end
server = parepare_server
server.start
server.join

```

### modify mail in proxy 

To rewrite mailbody in proxy by man-in-the-middle.

just overload `on_proxy_send_mail` method. in your class 
```ruby
class MyServer <Takuya::GMailForwarderServer
  # @overload on_proxy_send_mail()
  # @return envelope_from, envelope_to, mail
  # @param mail [Mail::Message]
  # @param envelope_from [String]
  # @param envelope_to [Enumerable]
  def on_proxy_send_mail(envelope_from, envelope_to, mail)
    return envelope_from, envelope_to, mail
  end

end


```


## midi-smtp has crucial error

`long time task ` in `MidiSmtpServer` is not supported , it will raise tcp error.

Because of `not using Thread` and `not using EventEmitter` Event model, `MidiSmtpServer` will raise TCPError

### spec/sample.rb
```ruby
RSpec.describe 'MidiSmtpServer::Smtpd#on_message_data_event' do


  require 'mail'

  it " will occurs TCP Timeout" do

    class MyServer<MidiSmtpServer::Smtpd
      def something_long_task
        sleep 5
      end
      def on_message_data_event(ctx)
        something_long_task
      end
    end
    uuid = SecureRandom.uuid
    host_ip = "127.0.25.25"
    host_port = rand(49151...65535)
    user_id = :dummy
    server = MyServer.new(hosts:host_ip,ports:host_port)
    server.start

    mail = Mail.new{ |mail|
      mail.delivery_method(:smtp, address: host_ip, port: host_port)
      mail.from = user_id
      mail.to = user_id
      mail.subject = "Test Mail from proxy #{Date.today.strftime('%Y-%m-%d')} / #{uuid}"
      mail.body = "This is test from MidiSmtpServer::Smtpd. from #{host_ip}:#{host_port}. "
      mail.date = Time.now
      mail.mime_version = '1.0'
    }

    mail.deliver!
    server.stop

  end

end

```
## run
```
bundle exec rspec spec/sample.rb
```
## TCP error occurred
```
MidiSmtpServer::Smtpd#on_message_data_event
2024-09-24 15:57:36 +0900: [INFO] Starting service on 127.0.25.25:59604
2024-09-24 15:57:36 +0900: [DEBUG] Client connect from 127.0.0.1:47056 to 127.0.25.25:59604
2024-09-24 15:57:36 +0900: [DEBUG] >>> 220 127.0.25.25 says welcome!
2024-09-24 15:57:36 +0900: [DEBUG] <<< EHLO localhost.localdomain
2024-09-24 15:57:36 +0900: [DEBUG] >>> 250-127.0.25.25 at your service!
250 OK
2024-09-24 15:57:36 +0900: [DEBUG] <<< MAIL FROM:<dummy>
2024-09-24 15:57:36 +0900: [DEBUG] >>> 250 OK
2024-09-24 15:57:37 +0900: [DEBUG] <<< RCPT TO:<dummy>
2024-09-24 15:57:37 +0900: [DEBUG] >>> 250 OK
2024-09-24 15:57:37 +0900: [DEBUG] <<< DATA
2024-09-24 15:57:37 +0900: [DEBUG] >>> 354 Enter message, ending with "." on a line by itself
  will occurs TCP Timeout (FAILED - 1)

Failures:

  1) MidiSmtpServer::Smtpd#on_message_data_event  will occurs TCP Timeout
     Failure/Error: mail.deliver!

     Net::ReadTimeout:
       Net::ReadTimeout with #<TCPSocket:(closed)>
     # ./vendor/bundle/ruby/3.1.0/gems/net-protocol-0.2.2/lib/net/protocol.rb:229:in `rbuf_fill'
     # ./vendor/bundle/ruby/3.1.0/gems/net-protocol-0.2.2/lib/net/protocol.rb:199:in `readuntil'
     # ./vendor/bundle/ruby/3.1.0/gems/net-protocol-0.2.2/lib/net/protocol.rb:209:in `readline'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:1017:in `recv_response'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:979:in `block in data'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:1027:in `critical'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:965:in `data'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:799:in `block in send_message'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:926:in `rcptto_list'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:799:in `send_message'
     # ./vendor/bundle/ruby/3.1.0/gems/mail-2.8.1/lib/mail/network/delivery_methods/smtp_connection.rb:53:in `deliver!'
     # ./vendor/bundle/ruby/3.1.0/gems/mail-2.8.1/lib/mail/network/delivery_methods/smtp.rb:101:in `block in deliver!'
     # ./vendor/bundle/ruby/3.1.0/gems/net-smtp-0.5.0/lib/net/smtp.rb:643:in `start'
     # ./vendor/bundle/ruby/3.1.0/gems/mail-2.8.1/lib/mail/network/delivery_methods/smtp.rb:109:in `start_smtp_session'
     # ./vendor/bundle/ruby/3.1.0/gems/mail-2.8.1/lib/mail/network/delivery_methods/smtp.rb:100:in `deliver!'
     # ./vendor/bundle/ruby/3.1.0/gems/mail-2.8.1/lib/mail/message.rb:269:in `deliver!'
     # ./spec/prevent-timeout_spec.rb:33:in `block (2 levels) in <top (required)>'

Finished in 5.62 seconds (files took 0.77611 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/prevent-timeout_spec.rb:6 # MidiSmtpServer::Smtpd#on_message_data_event  will occurs TCP Timeout

2024-09-24 15:57:42 +0900: [DEBUG] Client disconnect from 127.0.0.1:47056 on 127.0.25.25:59604
```

To prevent TCPError in smtp client, I wrote monkey patch.
I added `io.disconnect` in server Thread, it works fine. 



