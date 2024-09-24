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
    @mail_received = nil

    public

    # @param received_message [Mail::Message]
    def on_message_received(envelope_from, envelope_to, received_message) end

    protected

    def on_message_data_event(ctx)
      @mail_received = {
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
      binding_message_variable = lambda { |last_msg|
        current_received = last_msg.dup
        lambda {
          on_message_received(
            current_received[:envelope_from],
            current_received[:envelope_from],
            Mail.read_from_string(current_received[:message_encoded])
          ) }
      }
      on_disconnected = binding_message_variable.call(@mail_received)
      ##
      io.close
      Thread.pass
      Thread.new{on_disconnected.call}.join
    end
  end
end
