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
        @submission.status = 0
        @submission.save
      elsif current_user.admin and @submission.status == 0
        @submission.status = 1
        @submission.save
      end
      # Redirect to the submission
      redirect_to problem_submission_path(@submission.problem,
                                          @submission),
                                          flash: {success:
                                            'Réponse postée'}
    else
      flash_errors(correction)
      render 'submission/show'
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
