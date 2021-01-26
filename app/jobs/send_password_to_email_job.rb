class SendPasswordToEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id,password)
    user = User.find(user_id)
    api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
    send_smtp_email = SibApiV3Sdk::SendSmtpEmail.new
    sender = SibApiV3Sdk::SendSmtpEmailSender.new(name: 'admin-puri-ayana', email: 'no-reply@puriayanagempol.com')
    send_smtp_email.subject = '[Puri Ayana App] - Ini password anda!'
    send_smtp_email.to = [{name: user.name, email: user.email}]
    send_smtp_email.sender = sender
    send_smtp_email.html_content = "<html>
    <head>
      <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
    </head>
    <body>
      <p>Hello #{user.name}!</p>
      <p>
      Ini adalah password yang bisa anda gunakan untuk login ke applikasi Puri Ayana.<br>
      --------------------------
      </p>
      <p>Password Anda: <b>#{password}</b></p>
      <br>
      ----------
      </p>
      <p>
        Terima Kasih dan Selamat beraktifitas.
        Semoga Anda senantiasa sehat dan diberikan kemurahan rejeki, Aamiin.

        Salam, <br />
        Pengurus
      </p>
    </body>
  </html>
  "
    begin
      result = api_instance.send_transac_email(send_smtp_email)    
      p result
    rescue SibApiV3Sdk::ApiError => e
      puts "Exception when calling TransactionalEmailsApi->send_transac_email: #{e}"
    end
  end
end

