class String
  def my_titleize
    humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
  end
end

