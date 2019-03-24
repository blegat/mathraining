class StaticPagesController < ApplicationController
  before_action :signed_in_user, only: [:statistics]
  before_action :root_user, only: [:statistics]
end
