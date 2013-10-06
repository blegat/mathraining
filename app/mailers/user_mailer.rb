#encoding: utf-8
class UserMailer < AsyncMailer

  # include Resque::Mailer
  
  def registration_confirmation(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Confirmation d'inscription", from: "no-reply@mathraining.be")
  end
  
  def forgot_password(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Mot de passe oublié", from: "no-reply@mathraining.be")
  end
  
  def new_followed_message(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Mot de passe oublié", from: "no-reply@mathraining.be")
  end
end
