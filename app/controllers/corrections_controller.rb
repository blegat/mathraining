#encoding: utf-8
class CorrectionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :correct_user

  def create
    correction = @submission.corrections.build(params[:correction])
    correction.user = current_user
    if correction.save
      # Change the status of the submission
      # We don't change the status if it is 2 (solved)
      if current_user == @submission.user and @submission.status == 1
        @submission.status = 3
        @submission.save
        m = ''
      elsif current_user.admin and (@submission.status == 0 or @submission.status == 3) and params[:commit] == "Poster réponse et rendre la soumission fausse"
        @submission.status = 1
        @submission.save
        m = ' et soumission marquée comme incorrecte'
      elsif current_user.admin and params[:commit] == "Poster réponse et rendre la soumission correcte"
        @submission.status = 2
        @submission.save
        unless @submission.user.solved?(@submission.problem)
          @submission.problem.users << @submission.user
        end
        m = ' et soumission marquée comme correcte'
      end
      # Redirect to the submission
      redirect_to problem_submission_path(@submission.problem, @submission),
        flash: { success: "Réponse postée#{m}" }
    else
      if params[:correction][:content].size == 0
        redirect_to problem_submission_path(@submission.problem, @submission),
          flash: { error: 'Votre réponse est vide.' }
      elsif params[:correction][:content].size > 8000
        redirect_to problem_submission_path(@submission.problem, @submission),
          flash: { error: 'Votre réponse doit faire moins de 8000 caractères.' }
      else
        redirect_to problem_submission_path(@submission.problem, @submission),
          flash: { error: 'Une erreur est survenue.' }
      end
    end
  end

  private

  def correct_user
    @submission = Submission.find_by_id(params[:submission_id])
    if @submission.nil? or (@submission.user != current_user and not current_user.admin)
      redirect_to root_path
    end
  end
end
