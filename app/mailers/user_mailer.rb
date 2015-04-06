#encoding: utf-8
class UserMailer < AsyncMailer

  include Resque::Mailer

  def registration_confirmation(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Confirmation d'inscription", from: "mathraining@mathraining.be")
  end

  def forgot_password(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Mot de passe oublié", from: "mathraining@mathraining.be")
  end

  def new_followed_message(userid, subjectid, qui, message, id)
    @user = User.find(userid)

    mail(to: @user.email, subject: "Mathraining - Nouveau message sur le sujet", from: "mathraining@mathraining.be")
  end
end
