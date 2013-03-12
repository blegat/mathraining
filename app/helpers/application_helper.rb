module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "OMB training"
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end

  def flash_errors(object)
    unless object.errors.empty?
      flash.now[:error] = object.errors.full_messages.to_sentence
    end
  end
  def get_errors(object)
    unless object.errors.empty?
      object.errors.full_messages.to_sentence
    end
  end

end
