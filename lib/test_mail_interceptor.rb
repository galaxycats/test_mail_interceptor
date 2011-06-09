class TestMailInterceptor
 
  def self.delivering_email(mail)
    if Rails.application.config.mail_interceptor.intercept_mail
      interceptor = new(mail)
      interceptor.handle_multipart_mail
      interceptor.change_original_recipients_to_test_recipients
      interceptor.clean_cc_and_bcc_recipients

      return interceptor.mail
    end

    return mail
  end

  attr_reader :mail

  def initialize(mail)
    @mail = mail
  end

  def handle_multipart_mail
    if mail.multipart?
      mail.parts.each do |part|
        if part.content_type =~ /^text\/html/
          part.body = generate_test_mail_header_html + part.body.raw_source
        else
          part.body = generate_test_mail_header + part.body.raw_source
        end
      end
    else
      mail.body = generate_test_mail_header + mail.body.raw_source
    end
  end

  def change_original_recipients_to_test_recipients
    mail.to = Rails.application.config.mail_interceptor.test_recipient
  end

  def clean_cc_and_bcc_recipients
    mail.cc = nil
    mail.bcc = nil
  end

  private

    def generate_test_mail_header
      %Q{------------------------------- Test-Mail (#{Rails.env}) -------------------------------
         Original-Recipient: #{mail.to.join(", ")}
         CC: #{mail.cc ? mail.cc.join(", ") : "no CC"}
         BCC: #{mail.bcc ? mail.bcc.join(", ") : "no BCC"}
         ----------------------------------------------------------------------------------
      }.gsub(/^\s+/, '')
    end
    
    def generate_test_mail_header_html
      generate_test_mail_header.gsub(/\n/, "<br>")
    end

end
