#!bin/rails runner

$picture_id = 0
$num_occurrences = []
$unused_pictures = []
$errors = []
$summaries = []
$details = []

def find_first_picture_in_text(text)
  text_to_search = "/pictures/"
  if $picture_id > 0
    text_to_search += $picture_id.to_s + "/image"
  end
  a = text.index(text_to_search)
  if a.nil?
    return nil
  end
  b = a + text_to_search.size
  if $picture_id == 0
    id = 0
    while text[b].match?(/[[:digit:]]/)
      id *= 10
      id += text[b].to_i
      b += 1
    end
    if $num_occurrences[id].nil?
      $errors.append("Found non-existing picture with id " + id.to_s)
    else
      $num_occurrences[id] += 1
    end
  end
  return text[b..-1]
end

def find_pictures_in_text(text)
  ret = 0
  while true do
    new_text = find_first_picture_in_text(text)
    if new_text.nil?
      break
    else
      ret = ret + 1
      text = new_text
    end
  end
  return ret
end

def find_pictures_in_object(object, att)
  text = object.read_attribute(att)
  return find_pictures_in_text(text)
end

def find_pictures_in_model(model, att)
  res = 0
  model.find_each.each do |object|
    x = find_pictures_in_object(object, att)
    if x > 0
      $details.append("Found " + x.to_s + " occurrences in attribute " + att + " of object " + object.id.to_s + " of " + model.to_s)
      res = res + x
    end
  end
  $summaries.append("Found " + res.to_s + " occurrences in attribute " + att + " of " + model.to_s)
  return res
end

def find_pictures_in_mathraining(picture_id = 0)
  $picture_id = picture_id
  if picture_id == 0
    Picture.all.each do |p|
      $num_occurrences[p.id] = 0
    end
  end
  res = 0
  res = res + find_pictures_in_model(Actuality, "content")
  res = res + find_pictures_in_model(Theory, "content")
  res = res + find_pictures_in_model(Question, "statement")
  res = res + find_pictures_in_model(Question, "explanation")
  res = res + find_pictures_in_model(Problem, "statement")
  res = res + find_pictures_in_model(Problem, "explanation")
  res = res + find_pictures_in_model(Contestproblem, "statement")
  res = res + find_pictures_in_model(Section, "description")
  res = res + find_pictures_in_model(Chapter, "description")
  res = res + find_pictures_in_model(Contest, "description")
  res = res + find_pictures_in_model(Privacypolicy, "content")
  res = res + find_pictures_in_model(Item, "ans")
  $summaries.append("Found " + res.to_s + " occurrences in total")
  if picture_id == 0
    Picture.order(:id).all.each do |p|
      if $num_occurrences[p.id] == 0
        $unused_pictures.append(p.id)
      end
    end
  end
end
