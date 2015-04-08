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
    @subject = Subject.find(subjectid)
    @qui = qui
    @message = message
    @id = id
    @tot = @subject.messages.count
    @page = [0,((@tot-1)/10).floor].max + 1
    mail(to: @user.email, subject: "Mathraining - Nouveau message sur le sujet '" + @subject.title + "'", from: "mathraining@mathraining.be")
  end

  def new_followed_tchatmessage(userid, qui, message, id)
    @user = User.find(userid)
    @qui = qui
    @message = message
    @id = id
    mail(to: @user.email, subject: "Mathraining - Nouveau message de '" + @qui + "'", from: "mathraining@mathraining.be")
  end
end
