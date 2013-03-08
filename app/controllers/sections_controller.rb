class SectionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :recup,
    only: [:destroy, :show, :edit, :update]
  before_filter :admin_user,
    only: [:destroy, :edit, :update]

  def index
    @sections = Section.all
  end
  def create
    @section = Section.new(params[:section])
  	if @section.save
  	  flash[:success] = "Section ajoutee."
  	  redirect_to @section
  	else
  	  render 'new'
  	end
  end
  def show
  end
  def new
  	@section = Section.new
  end
  def edit
  end
  def update
  if @section.update_attributes(params[:section])
      flash[:success] = "Section modifiee."
      redirect_to @section
    else
      render 'edit'
    end
  end
  def destroy
    @section.destroy
    flash[:success] = "Section supprimee."
    redirect_to sections_path
  end

  private
  def recup
    @section = Section.find(params[:id])
  end
  def admin_user
    redirect_to @section unless current_user.admin?
  end
  
end





