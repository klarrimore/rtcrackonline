class Notifier < ActionMailer::Base
  
  def send_out(email, hash, text)
    @recipients = email
    @from = "keith@shmoo.com"
    @subject = "Shmoo hash successfully cracked a password." 
    @body = "\n" + hash + " decrypted is " + text + "\n" 
  end

end
