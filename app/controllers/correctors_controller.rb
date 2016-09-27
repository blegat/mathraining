#encoding: utf-8

class CorrectorsController < ApplicationController
  before_filter :signed_in_user, only: [:index]

  # Index de tous les correcteurs
  def index
  end

  ########## PARTIE PRIVEE ##########
  private

end
