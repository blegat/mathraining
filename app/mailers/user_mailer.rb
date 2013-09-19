#encoding: utf-8
class UserMailer < ActionMailer::Base
  def registration_confirmation(user)
    @user = user
    mail(to: user.email, subject: "MathRaining - Confirmation d'inscription", from: "no-reply@mathraining.be")
  end
  
  def forgot_password(user)
    @user = user
    mail(to: user.email, subject: "MathRaining - Mot de passe oublié", from: "no-reply@mathraining.be")
  end
end
