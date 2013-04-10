#encoding: utf-8
class ActualitiesController < ApplicationController
  before_filter :signed_in_user,
    only: [:destroy, :update, :edit, :new, :create]
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

  def feed
    # this will be the name of the feed displayed on the feed reader
    @title = "OMB training feed"

    # the news items
    @news_items = Actuality.order("updated_at desc")

    # this will be our Feed's update timestamp
    @updated = @news_items.first.updated_at unless @news_items.empty?

    respond_to do |format|
      format.atom { render :layout => false }

      # we want the RSS feed to redirect permanently to the ATOM feed
      format.rss { redirect_to feed_path(:format => :atom), status: :moved_permanently }
    end
  end

  private

  def admin_user
    redirect_to root_path unless current_user.admin?
  end
end
