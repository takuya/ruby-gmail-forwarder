module Takuya
  # Server class
  class GMailForwarderServer< Takuya::MidiSmtpServer

    def initialize(user_id: nil, password: nil, client_secret_path: nil, token_path: nil, **args)
      super(internationalization_extensions: true, **args)
      unless user_id && (password || (client_secret_path && token_path))
        raise 'user_id and password(plain or token paths ) must be specified'
      end
      @user_id, @client_secret_path, @token_path, @password = user_id, client_secret_path, token_path, password
    end

    def on_message_received(envelope_from,envelope_to,received_message)
      proxy_smtp_sendmail(envelope_from, envelope_to, received_message)
    end

    # @param mail [Mail::Message]
    # @param envelope_from [String]
    # @param envelope_to [Enumerable]
    def proxy_smtp_sendmail(envelope_from, envelope_to, mail)
      envelope_from, envelope_to, mail = on_proxy_send_mail(envelope_from, envelope_to, mail)
      forward_to_gmail(envelope_from, envelope_to, mail)
    rescue => e
      $stderr.puts e.message
      $stderr.puts e.backtrace
    end

    ## modify proxied mail as your need.
    # @return envelope_from, envelope_to, mail
    # @param mail [Mail::Message]
    # @param envelope_from [String]
    # @param envelope_to [Enumerable]
    def on_proxy_send_mail(envelope_from, envelope_to, mail)
      [ envelope_from, envelope_to, mail]
    end

    # @return [Net::SMTP]
    def connect_google_smtp
      if @password
        smtp = Net::SMTP.new("smtp.gmail.com", 587)
        smtp.enable_starttls
        smtp.start('smtp.gmail.com', @user_id, @password, :login)
        smtp
      end
      unless smtp
        smtp = Takuya::XOAuth2::GMailXOAuth2.smtp(@client_secret_path, @token_path, @user_id)
      end
      smtp
    end

    # @param mail [Mail::Message]
    # @param envelope_from [String]
    # @param envelope_to [Enumerable]
    def forward_to_gmail(envelope_from, envelope_to, mail)
      ## prepare
      res = {}
      smtp = connect_google_smtp
      ## send mail
      res[:sendmail] = smtp.sendmail(mail.encoded, envelope_from, envelope_to)
      ## finish
      res[:status] = smtp.finish
      res[:sendmail]==nil && res[:status].to_i==221
    end
  end
end
