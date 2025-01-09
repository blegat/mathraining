#encoding: utf-8
class SolvedproblemsController < ApplicationController

  # Show all (recently) solved problems
  def index
    @max_date = Date.today
    @min_date = Date.today - 6.days
    if params.has_key?(:date)
      @date = (params.has_key?(:date) ? (Date.parse(params[:date]) rescue @max_date) : @max_date)
      @date = @max_date if @date > @max_date
      @date = @min_date if @date < @min_date
    else
      @date = @max_date
    end
    @solvedproblems = Solvedproblem.joins(:problem).joins(problem: :section).joins("LEFT JOIN followings ON followings.submission_id = solvedproblems.submission_id").select("solvedproblems.user_id, solvedproblems.problem_id, solvedproblems.submission_id, problems.number AS problem_number, problems.level, solvedproblems.correction_time, sections.short_abbreviation AS section_short_abbreviation, followings.user_id AS corrector_id").includes(:user, submission: {followings: :user}).where(followings: {kind: :first_corrector}).where(correction_time: @date.all_day).order("correction_time DESC").to_a
  end
end
