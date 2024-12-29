#encoding: utf-8
class PuzzlesController < ApplicationController
  before_action :signed_in_user, only: [:index, :new, :edit, :main, :graph]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order, :attempt]
  before_action :root_user, only: [:index, :new, :create, :edit, :update, :destroy, :order]
  
  before_action :get_puzzle, only: [:edit, :update, :destroy, :order, :attempt]
  
  before_action :after_start_date, only: [:main, :graph, :attempt]
  before_action :before_end_date, only: [:new, :create, :destroy, :order, :attempt]
  before_action :user_not_in_skin, only: [:attempt]
  
  # Show all the puzzles (for a root)
  def index
  end
  
  # Main page for puzzles
  def main
  end
  
  # Page with graph puzzle
  def graph
  end

  # Create a puzzle (show the form)
  def new
    @puzzle = Puzzle.new
  end

  # Update a puzzle (show the form)
  def edit
  end
  
  # Create a puzzle (send the form)
  def create
    last_puzzle = Puzzle.order(:position).last
    params[:puzzle][:code].upcase! if params[:puzzle].has_key?(:code)
    @puzzle = Puzzle.new(params.require(:puzzle).permit(:statement, :code, :explanation))
    @puzzle.position = (last_puzzle.nil? ? 1 : last_puzzle.position + 1)
    if @puzzle.save
      flash[:success] = "Énigme ajoutée."
      redirect_to puzzles_path
    else
      render 'new'
    end
  end

  # Update a puzzle (send the form)
  def update
    params[:puzzle][:code].upcase! if params[:puzzle].has_key?(:code)
    if @puzzle.update(params.require(:puzzle).permit(:statement, :code, :explanation))
      flash[:success] = "Énigme modifiée."
      redirect_to puzzles_path
    else
      render 'edit'
    end
  end

  # Delete a puzzle
  def destroy
    @puzzle.destroy
    flash[:success] = "Énigme supprimée."
    redirect_to puzzles_path
  end

  # Move the puzzle to another position
  def order
    puzzle2 = Puzzle.where("position = ?", params[:new_position]).first
    if !puzzle2.nil? && puzzle2 != @puzzle
      res = swap_position(@puzzle, puzzle2)
      flash[:success] = "Énigme déplacée#{res}."
    end
    redirect_to puzzles_path
  end
  
  # Send an attempt to the puzzle (via JS only)
  def attempt
    code = params[:code]
    puzzleattempt = Puzzleattempt.where(:user => current_user, :puzzle => @puzzle).first
    if code.nil? || code.size == 0
      puzzleattempt.destroy unless puzzleattempt.nil?
      @code_ok = true
      @new_code = ""
    else
      code.upcase!
      puzzleattempt = Puzzleattempt.new(:user => current_user, :puzzle => @puzzle) if puzzleattempt.nil?
      puzzleattempt.code = code
      if puzzleattempt.save
        @code_ok = true
        @new_code = code
      else
        @code_ok = false
      end
    end
    respond_to do |format|
      format.js
    end
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the puzzle
  def get_puzzle
    @puzzle = Puzzle.find_by_id(params[:id])
    return if check_nil_object(@puzzle)
  end
  
  ########## CHECK METHODS ##########
  
  # Check we are after the start date
  def after_start_date
    if !Puzzle.started_or_root(current_user)
      render 'errors/access_refused'
    end
  end
  
  # Check we are before the end date
  def before_end_date
    if Puzzle.ended?
      render 'errors/access_refused'
    end
  end
end
