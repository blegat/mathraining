#encoding: utf-8

# == Schema Information
#
# Table name: colors
#
#  id           :integer          not null, primary key
#  pt           :integer
#  name         :string
#  color        :string
#  femininename :string
#  dark_color   :string
#
class Color < ActiveRecord::Base

  # VALIDATIONS

  validates :pt, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :femininename, presence: true, length: { maximum: 255 }
  validates :color, presence: true, length: { is: 7 }
  validates :dark_color, presence: true, length: { is: 7 }
  
  # OTHER METHODS
  
  def self.get_all
    if $allcolors.nil? || Rails.env.test? # Need to reload in tests because Colors can change
      $allcolors = Color.order(:pt).to_a
    end
    return $allcolors
  end
  
  # DEFAULTS
  
  def self.create_defaults
    Color.create(pt: 0,    name: "Novice",       color: "#888888", dark_color: "#A0A0A0", femininename: "Novice")
    Color.create(pt: 70,   name: "Débutant",     color: "#08D508", dark_color: "#20F720", femininename: "Débutante")
    Color.create(pt: 200,  name: "Initié",       color: "#008800", dark_color: "#00D300", femininename: "Initiée")
    Color.create(pt: 400,  name: "Compétent",    color: "#00BBEE", dark_color: "#25D0FF", femininename: "Compétente")
    Color.create(pt: 750,  name: "Qualifié",     color: "#0033FF", dark_color: "#335CFF", femininename: "Qualifiée")
    Color.create(pt: 1250, name: "Expérimenté",  color: "#DD77FF", dark_color: "#E492FF", femininename: "Expérimentée")
    Color.create(pt: 2000, name: "Chevronné",    color: "#A000A0", dark_color: "#BF00E6", femininename: "Chevronnée")
    Color.create(pt: 3200, name: "Expert",       color: "#FFA000", dark_color: "#FFB333", femininename: "Experte")
    Color.create(pt: 5000, name: "Maître",       color: "#FF4400", dark_color: "#FF6933", femininename: "Maître")
    Color.create(pt: 7500, name: "Grand Maître", color: "#CC0000", dark_color: "#FF0A0A", femininename: "Grand Maître")
  end
end
