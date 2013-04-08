#encoding: utf-8
class ActualitiesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create]


  def new
    @actuality = Actuality.new
  end

  def edit
    @actuality = Actuality.find(params[:id])
  end

  def create
    @actuality = Actuality.create(params[:actuality])
    if @actuality.save
      flash[:success] = "Actualité ajoutée."
      redirect_to root_path
    else
      render 'new'
    end
  end

  def update
    @actuality = Actuality.find(params[:id])
    if @actuality.update_attributes(params[:actuality])
      flash[:success] = "Actualité modifiée."
      redirect_to root_path
    else
      render 'edit'
    end
  end

  def destroy
    @actuality = Actuality.find(params[:id])
    @actuality.destroy
    flash[:success] = "Actualité supprimée."
    redirect_to root_path
  end

  private

  def admin_user
    redirect_to root_path unless current_user.admin?
  end
end
