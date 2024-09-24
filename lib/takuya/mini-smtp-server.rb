module Takuya
  ##
  # MidiSmtpServer::Smtpd#on_message_data_event(ctx) will occur 'ReadTimeout' in client
  # ```ruby
  # class MyServer<MidiSmtpServer::Smtpd
  # on_message_data_event(ctx); sleep 5; done
  # ```
  # long time processing in on_message_data_event will be timeout.
  # To prevent timeout err, insert `on_disconnected` event handler
  class MidiSmtpServer<MidiSmtpServer::Smtpd


    public

    # @param received_message [Mail::Message]
    def on_message_received(envelope_from, envelope_to, received_message) end

    protected

    def on_connect_event(ctx)
      @mail_received = Queue.new
    end

    def on_message_data_event(ctx)
      @mail_received << {
        envelope_from: ctx[:envelope][:from].gsub(%r'[<>]', ''),
        envelope_to: ctx[:envelope][:to].map { |e| e.gsub(%r'[<>]', '') },
        message_encoded: ctx[:message][:data]
      }
    end

    ## prevent [Net::ReadTimeout] in on_message_data_event.
    #
    def serve_client(session, io)
      # @type io [TCPSocket]
      io = super(session, io)
      on_disconnected = lambda { |messages|
        until messages.empty?
          m = messages.pop
          on_message_received(m[:envelope_from], m[:envelope_to], Mail.read_from_string(m[:message_encoded]))
        end
      }
      ##
      io.close
      on_disconnected.call(@mail_received)
      @mail_received = nil
    end
  end
end
