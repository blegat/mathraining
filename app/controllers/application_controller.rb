#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper
  include MarkdownHelper
  
  def whatcolors
    # OPTIONS FOR RATINGS
    @price = 15
    @pricefondement = 15
    @niveaux = [
    {:pt => 0, :name => "Novice", :color => "#888888", :fontcolor => "#BBBBBB"},
    {:pt => 10, :name => "Débutant", :color => "#11DD44", :fontcolor => "#33FF66"},
    {:pt => 20, :name => "Initié", :color => "#11AA00", :fontcolor => "#44DD11"},
    {:pt => 30, :name => "Compétent", :color => "#00BBEE", :fontcolor => "#33FFFF"},
    {:pt => 40, :name => "Qualifié", :color => "#0033FF", :fontcolor => "#6699FF"},
    {:pt => 50, :name => "Expérimenté", :color => "#DD77FF", :fontcolor => "#FF99FF"},
    {:pt => 60, :name => "Chevronné", :color => "#990099", :fontcolor => "#DD44DD"},
    {:pt => 70, :name => "Expert", :color => "#FF9900", :fontcolor => "#FFBB22"},
    {:pt => 80, :name => "Maître", :color => "#FF3300", :fontcolor => "#FF5522"},
    {:pt => 90, :name => "Grand Maître", :color => "#CC0000", :fontcolor => "#EE2222"}
    ]
  end

end
