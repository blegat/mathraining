	#encoding: utf-8

# == Schema Information
#
# Table name: sponsorwords
#
#  id   :integer          not null, primary key
#  word :string
#  used :boolean          default(FALSE)
#
class Sponsorword < ActiveRecord::Base
  def self.words(content)
    w = []
    content.downcase.gsub(/\!/, ' ').gsub(/\?/, ' ').gsub(/\-/, ' ').gsub(/\,/, ' ').gsub(/\./, ' ').gsub(/\(/, ' ').gsub(/\)/, ' ').gsub(/\'/, ' ').split.each do |d|
      if d.size >= 2
        k = 0
        (0..(d.size-1)).each do |i|
          if k == 0 && d[i] == 'd'
            k = 1
          elsif k == 1 && d[i] == 'l'
            k = 2
            break
          end
        end
        if k == 2
          x = Sponsorword.where(:word => d).first
          if !x.nil?
            w.push(x)
          end
        end
      end
    end
    return w
  end
  
  def self.replaceSponsorInWords(content)
    if $all_words.nil?
      $all_words = Sponsorword.all.to_a.map{ |r|  r.word }.to_set
    end
  
    cur = ""
    to_replace = []
    (0..(content.size)).each do |i|
      if i == content.size || content[i] == ' ' || content[i] == "\n" || content[i] == "\r" || content[i] == '-' || content[i] == '.' || content[i] == ',' || content[i] == '?' || content[i] == '!' || content[i] == '(' || content[i] == ')' || content[i] == ';' # for ' = &#39;
        if cur.size >= 2
          print(cur)
          print("\n")
          curdown = cur.downcase
          k = 0
          a = -1
          b = -1
          (0..(curdown.size-1)).each do |j|
            if k == 0 && curdown[j] == 'd'
              k = 1
              a = j
            elsif k == 1 && curdown[j] == 'l'
              k = 2
              b = j
              break
            end
          end
          if k == 2
            if $all_words.include?(curdown)
              to_replace.push(i-cur.size+a)
              to_replace.push(i-cur.size+b)
            end
          end
        end
        cur = ""
      elsif i < content.size
        cur = cur + content[i]
      end
    end
   
    new_content = ""
    l = content.size
    u = 'd'
    to_replace.reverse.each do |i|
      u = (u == 'l' ? 'd' : 'l')
      new_content = ActionController::Base.helpers.image_tag(u + ".png", :height => "16px", :style => "margin-top:-5px; margin-left:1px; margin-right:1px;") + content[i+1, l-i-1] + new_content
      l = i
    end
    if l > 0
      new_content = content[0..l-1] + new_content
    end
    return new_content
  end
end
