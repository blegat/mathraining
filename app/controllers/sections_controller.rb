#encoding: utf-8
class SectionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :recup,
    only: [:destroy, :show, :edit, :update]
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create]

  def index
    @sections = Section.all
  end
  def create
  end
  def show
  end
  def new
  	@section = Section.new
  end
  def edit
  end
  def update
  if @section.update_attributes(name: params[:section][:name], description: params[:section][:description])
      flash[:success] = "Section modifiée."
      redirect_to @section
    else
      render 'edit'
    end
  end
  def destroy
  end

  private
  def recup
    @section = Section.find(params[:id])
  end
  def admin_user
    redirect_to @section unless current_user.admin?
  end
  
end





