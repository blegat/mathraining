#encoding: utf-8
class UserMailer < ActionMailer::Base
  def registration_confirmation(user)
    @user = user
    mail(to: user.email, subject: "OMB training - Confirmation d'inscription", from: "confirmation@ombtraining.com")
  end
  
  def forgot_password(user)
    @user = user
    mail(to: user.email, subject: "OMB training - Mot de passe oublié", from: "confirmation@ombtraining.com")
  end
end
