class RenameSomeColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :chapters, :publication_time, :publication_date
    rename_column :chapters, :nb_solved, :nb_completions
    rename_column :discussions, :last_message, :last_message_time
    rename_column :questions, :nb_firstguess, :nb_first_guesses
    rename_column :problems, :first_solved, :first_solve_time
    rename_column :problems, :last_solved, :last_solve_time
    rename_column :problems, :nb_solved, :nb_solves
    rename_column :privacypolicies, :publication, :publication_time
    rename_column :records, :number_submission, :nb_submissions
    rename_column :records, :number_solved, :nb_questions_solved
    rename_column :records, :correction_time, :avg_correction_time
    rename_column :solvedproblems, :resolutiontime, :correction_time
    rename_column :solvedproblems, :truetime, :resolution_time
    rename_column :solvedquestions, :resolutiontime, :resolution_time
    rename_column :subjects, :lastcomment, :last_comment_time
    rename_column :subjects, :lastcomment_user_id, :last_comment_user_id
    rename_column :subjects, :admin, :for_correctors
    rename_column :subjects, :wepion, :for_wepion
    rename_column :submissions, :lastcomment, :last_comment_time
    rename_column :takentests, :takentime, :taken_time
    rename_column :users, :seename, :see_name
    rename_column :users, :forumseen, :last_forum_visit_time
    rename_column :users, :last_connexion, :last_connexion_date
    rename_column :users, :consent_date, :consent_time
    rename_column :visitors, :number_admin, :nb_admins
    rename_column :visitors, :number_user, :nb_users
  end
end
