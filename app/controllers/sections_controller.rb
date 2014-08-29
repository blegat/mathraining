#encoding: utf-8
class SectionsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :new, :update, :edit, :destroy]
  before_filter :recup,
    only: [:destroy, :show, :edit, :update, :showpb]
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create]

  def index
    @sections = Section.order(:id).all
  end
  def create
  end
  def show
  end
  def showpb
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
    if @section.fondation
  	  @fondation = true
  	else
      @fondation = false
    end
  end

  def admin_user
    redirect_to @section unless current_user.sk.admin?
  end

end

