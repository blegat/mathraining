#encoding: utf-8
namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    make_users
    make_base_chapter
  end
end

def make_users
  # Admin
  User.create!(first_name: 'Root',
               last_name: 'Admin',
               email: 'root@admin.com',
               password: 'foobar',
               password_confirmation: 'foobar',
               admin: true)
  # Student
  User.create!(first_name: 'Jean',
               last_name: 'Dupont',
               email: 'jean@dupont.com',
               password: 'foobar',
               password_confirmation: 'foobar')
end

def make_base_chapter
  base = Chapter.create!(name: 'Base de la base',
                         description: 'C\'est vraiment la base !',
                         level: 0,
                         online: true)
  base.theories << Theory.create!(title: 'Addition',
                                  content: 'L\'addition (e.g. $1 + 2$) est <i>associative</i> et <i>commutative</i>.',
                                  position: 1,
                                  online: true)
  base.theories << Theory.create!(title: 'Multiplication',
                                  content: 'La multiplication (e.g. $6 \times 7$) est <i>associative</i> et <i>commutative</i>.',
                                  position: 2,
                                  online: true)
  base.theories << Theory.create!(title: 'Division',
                                  content: 'La division (e.g. $12 / 3$) est considérée comme l\'opération opposée à la multiplication.',
                                  position: 3,
                                  online: true)
  base.exercises << Exercise.create!(statement: 'Que vaut $3 + 5$?',
                                     answer: 8,
                                     decimal: false,
                                     position: 1,
                                     explanation: "Il suffit d'utiliser les règles expliquées dans la théorie.",
                                     online: true)
  base.exercises << Exercise.create!(statement: 'Que vaut $3.24 \times 10$?',
                                     answer: 32.4,
                                     decimal: true,
                                     position: 2,
                                     explanation: "Il suffit encore une fois d'utiliser les règles expliquées dans la théorie.",
                                     online: true)
  base.exercises << Exercise.create!(statement: 'Que vaut $6 / 3$?',
                                     answer: 2,
                                     decimal: false,
                                     position: 3,
                                     explanation: "",
                                     online: false)
  base.qcms << Qcm.create!(statement: 'Lesquelles de ces opérations donnent $3$?',
                           many_answers: true,
                           position: 4,
                           online: true,
                           explanation: "C'est évident.")

  Choice.create!(ans: "$5-2$", ok: true, qcm_id: 1)
  Choice.create!(ans: "$6/2$", ok: true, qcm_id: 1)
  Choice.create!(ans: "$12/3$", ok: false, qcm_id: 1)
  Choice.create!(ans: "$2+2$", ok: false, qcm_id: 1)

  base.exercises << Exercise.create!(statement: 'Que vaut $5 - 2$?',
                                     answer: 3,
                                     decimal: false,
                                     position: 5,
                                     explanation: "",
                                     online: true)
  base.problems << Problem.create!(name: 'Neutre',
                                  statement: 'Prouver que $0$ est neutre pour l\'addition',
                                  position: 1,
                                  online: true)
end

def make_words
  latin = Language.find_by_name("Latin")
  latin_words = []
  content = "est"
  99.times do |n|
    while latin_words.include?(content) do
      content = Faker::Lorem.sentence.split(' ')[0].downcase
    end
    word = latin.words.build(content: content)
    word.owner = User.random # uses random_record gem
    word.save!
    latin_words.push(content)
  end
  random = Language.find_by_name("Random")
  random_words = []
  99.times do |n|
    while random_words.include?(content) do
      content = Faker::Lorem.characters(5)
    end
    word = random.words.build(content: content)
    word.owner = User.random
    word.save!
    random_words.push(content)
  end
end

def make_links
  latin = Language.find_by_name("Latin")
  random = Language.find_by_name("Random")
  latin_words = latin.words
  random_words = random.words
  99.times do |n|
    latin_word_id = latin_words[rand(0..98)]
    random_word_id = random_words[rand(0..98)]
    link = Link.new
    link.word1 = latin_word_id
    link.word2 = random_word_id
    link.owner = User.random
    link.save # it could fail for same word1, word2
  end
end

def make_lists
  empty = true
  99.times do |n|
    list = List.new
    list.name = Faker::Lorem.words(1).to_s
    list.owner = User.random
    if Random.rand(2) == 0 and not empty
      list.parent = list.owner.lists.random
    end
    list.save!
    empty = false
  end
end
