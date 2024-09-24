RSpec.describe 'MidiSmtpServer::Smtpd on_message_data_event' do

  require_relative '../lib/takuya/mini-smtp-server'
  require 'mail'
  it " will occurs TCP Timeout" do
    $long_task_end = false

    class ServerWithRaiseTimeoutError<MidiSmtpServer::Smtpd
      def something_long_task(msg)
        sleep 5
        $long_task_end = true
      end

      def on_message_data_event(ctx)
        something_long_task(ctx[:message][:data])
      end

      def on_logging_event(_ctx, severity, msg, err: nil)
        ## do nothing.
      end
    end

    uuid = SecureRandom.uuid
    host_ip = "127.0.25.25"
    host_port = rand(49151...65535)
    user_id = :dummy
    server = ServerWithRaiseTimeoutError.new(hosts: host_ip, ports: host_port)
    server.start
    t = Thread.new {
      Thread.pass
      server.join
    }

    mail = Mail.new { |mail|
      mail.delivery_method(:smtp, address: host_ip, port: host_port)
      mail.from = user_id
      mail.to = user_id
      mail.subject = "Test Mail from proxy #{Date.today.strftime('%Y-%m-%d')} / #{uuid}"
      mail.body = "This is test from MidiSmtpServer::Smtpd. from #{host_ip}:#{host_port}. "
      mail.date = Time.now
      mail.mime_version = '1.0'
    }

    expect{mail.deliver!}.to raise_error Net::ReadTimeout
    server.stop

  end

  it " will not occur TCP Timeout(prevented)" do
    $long_task_end = false

    class ServerNoRaiseTimeoutError<Takuya::MidiSmtpServer
      @mail_received = nil

      def something_long_task(msg)
        Thread.new do
          sleep 5
          $long_task_end = true
        end.join
      end
      def on_logging_event(_ctx, severity, msg, err: nil)
        ## do nothing.
      end

      def on_message_received(from, to ,received_message)
        something_long_task(received_message)
      end
    end

    uuid = SecureRandom.uuid
    host_ip = "127.0.25.25"
    host_port = rand(49151...65535)
    user_id = :dummy
    server = ServerNoRaiseTimeoutError.new(hosts: host_ip, ports: host_port)
    server.start
    t = Thread.new {
      Thread.pass
      server.join
    }

    mail = Mail.new { |mail|
      mail.delivery_method(:smtp, address: host_ip, port: host_port)
      mail.from = user_id
      mail.to = user_id
      mail.subject = "Test Mail from proxy #{Date.today.strftime('%Y-%m-%d')} / #{uuid}"
      mail.body = "This is test from MidiSmtpServer::Smtpd. from #{host_ip}:#{host_port}. "
      mail.date = Time.now
      mail.mime_version = '1.0'
    }

    mail.deliver!
    until $long_task_end do
      sleep 1
    end
    server.stop

  end

end
