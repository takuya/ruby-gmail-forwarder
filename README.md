## SMTP to GMail Forwarder 

The PROXY-SMTP server relay to GMAIL-SMTP. This intended run as server.

## Installing

```sh
bundle init
REPO_URL=https://github.com/takuya/ruby-gmail-forwarder.git
echo "gem 'takuya-gmail-forwarder', :git '$REPO_URL'" >> Gemfile

## add dependency
DEP_URL=https://github.com/takuya/ruby-google-xoauth2.git
gem "'takuya-xoauth2', git: '$DEP_URL'" >> Gemfile
bundle add mail 
bundle add midi-smtp-server
bundle add dotenv
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

