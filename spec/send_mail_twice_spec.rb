RSpec.describe 'MidiSmtpServer::Smtpd on_message_data_event' do

  require_relative '../lib/takuya/mini-smtp-server'
  require 'mail'
  require 'net/smtp'

  class SingleMailSentServer<Takuya::MidiSmtpServer
    @mail_received = nil

    def something_long_task(msg)
      Thread.new do
        (0...5).each{sleep 1 }
        $long_task_end = true
      end.join
    end

    def on_logging_event(_ctx, severity, msg, err: nil)
      ## do nothing.
    end

    def on_message_received(from, to, received_message)
      $long_task_end = false
      $received_messages << received_message
      something_long_task(received_message)
    end
  end

  it " can accept DATA twice mail.deliver! ." do
    $long_task_end = false
    $received_messages = []
    $host_ip = "127.0.25.25"
    $host_port = rand(49151...65535)
    $user_id = :dummy
    uniq_ids = [SecureRandom.uuid, SecureRandom.uuid]
    $smtp = Net::SMTP.new($host_ip, $host_port)

    def send_mail(uuid)
      mail = Mail.new { |mail|
        mail.delivery_method(:smtp, address: $host_ip, port: $host_port)
        mail.from = $user_id
        mail.to = $user_id
        mail.subject = "Test Mail from proxy -- <#{uuid}>"
        mail.body = "This is test from MidiSmtpServer::Smtpd. from #{$host_ip}:#{$host_port}. "
        mail.date = Time.now
        mail.mime_version = '1.0'
      }
      mail.deliver!
    end

    server = SingleMailSentServer.new(hosts: $host_ip, ports: $host_port)
    server.start
    uniq_ids.each { |uuid| send_mail(uuid) }
    t = Thread.new {
      Thread.pass
      server.join
    }

    until $long_task_end do
      sleep 1
    end
    server.stop

    $received_messages.each_with_index { |msg, idx| expect(msg.subject).to include uniq_ids[idx] }

  end

  it " can accept DATA twice, via single smtp connection." do
    $long_task_end = false
    $received_messages = []
    $host_ip = "127.0.25.25"
    $host_port = rand(49151...65535)
    $user_id = "dummy"
    $smtp = Net::SMTP.new($host_ip, $host_port)

    def send_mail_via_smtp_connection(uuid)
      mail = Mail.new { |mail|
        mail.from = $user_id
        mail.to = $user_id
        mail.subject = "Test Mail from proxy -- <#{uuid}>"
        mail.body = "This is test from MidiSmtpServer::Smtpd. from #{$host_ip}:#{$host_port}. "
        mail.date = Time.now
        mail.mime_version = '1.0'
      }
      res = $smtp.sendmail(mail.encoded, $user_id, $user_id)
    end

    server = SingleMailSentServer.new(hosts: $host_ip, ports: $host_port)
    server.start
    $smtp.start

    ## using SMTP Connection and SendMail Twice.
    uniq_ids = [SecureRandom.uuid, SecureRandom.uuid]
    uniq_ids.each { |uid|
      send_mail_via_smtp_connection(uid)
    }
    $smtp.finish if $smtp.started?


    ##
    until $long_task_end do
      sleep 1
    end
    server.stop

    expect(
      $received_messages.map.with_index { |msg, idx|
        expect(msg.subject).to include uniq_ids[idx] }.all?
    ).to be true

    ## 接続が切れてることを確認
    expect($smtp.started?).to be false



  end

end
