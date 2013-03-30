class UserMailer < ActionMailer::Base
  def registration_confirmation(user)
    @user = user
    mail(to: user.email, subject: "OMB training - Confirmation d'inscription", from: "confirmation@ombtraining.com")
  end
end
