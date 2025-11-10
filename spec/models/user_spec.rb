# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  first_name                :string
#  last_name                 :string
#  email                     :string
#  password_digest           :string
#  remember_token            :string
#  created_at                :datetime         not null
#  key                       :string
#  email_confirm             :boolean          default(TRUE)
#  skin                      :integer          default(0)
#  see_name                  :integer          default(1)
#  sex                       :integer          default(0)
#  wepion                    :boolean          default(FALSE)
#  year                      :integer          default(0)
#  rating                    :integer          default(0)
#  last_forum_visit_time     :datetime         default(Thu, 01 Jan 2009 01:00:00.000000000 CET +01:00)
#  last_connexion_date       :date             default(Thu, 01 Jan 2009)
#  follow_message            :boolean          default(FALSE)
#  group                     :string           default("")
#  valid_name                :boolean          default(FALSE)
#  consent_time              :datetime
#  country_id                :integer
#  recup_password_date_limit :datetime
#  last_policy_read          :boolean          default(FALSE)
#  accept_analytics          :boolean          default(TRUE)
#  can_change_name           :boolean          default(TRUE)
#  correction_level          :integer          default(0)
#  corrector_color           :string
#  corrector                 :boolean          default(FALSE)
#  role                      :integer          default("student")
#  password_strength         :integer          default("unknown_password")
#  accepted_code_of_conduct  :boolean          default(FALSE)
#
require "spec_helper"

describe User, user: true do

  let!(:user) { FactoryBot.build(:user) }

  subject { user }

  it { should be_valid }

  # First name
  describe "when first_name is not present" do
    before { user.first_name = " " }
    it { should_not be_valid }
  end
  
  describe "when first_name is too long" do
    before { user.first_name = "a" * 33 }
    it { should_not be_valid }
  end
  
  describe "when first_name contains a digit" do
    before { user.first_name = "Henri-27" }
    it { should_not be_valid }
  end
  
  # Last name  
  describe "when last_name is not present" do
    before { user.last_name = " " }
    it { should_not be_valid }
  end
    
  describe "when last_name is too long" do
    before { user.last_name = "a" * 33 }
    it { should_not be_valid }
  end
  
  # Name, short name and full name
  describe "name, shortname, fullname" do
    before do
      user.first_name = "Jean"
      user.last_name = "Dupont"
      user.save
    end
    specify do
      expect(user.name).to eq("Jean Dupont")
      expect(user.fullname).to eq("Jean Dupont")
      expect(user.shortname).to eq("Jean D.")
    end
    
    describe "when see_name = 0" do
      before do
        user.see_name = 0
        user.save
      end
      specify do
        expect(user.name).to eq("Jean D.")
        expect(user.fullname).to eq("Jean Dupont")
        expect(user.shortname).to eq("Jean D.")
      end
    end
  end
  
  # Email
  describe "when email is not present" do
    before { user.email = " " }
    it { should_not be_valid }
  end

  describe "when email format is invalid" do
    specify do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.foo@bar_baz.com foo@bar+baz.com]
      addresses.each do |invalid_address|
      	user.email = invalid_address
      	user.email_confirmation = invalid_address
      	expect(user).not_to be_valid
      end
    end
  end

  describe "when email format is valid" do
    specify do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        user.email = valid_address
        user.email_confirmation = valid_address
        expect(user).to be_valid
      end
    end
  end
    
  describe "when email address is already taken" do
    let(:email_str) { user.email.dup }
    before { user_with_same_email = FactoryBot.create(:user, email: email_str.upcase, email_confirmation: email_str.upcase) }
    it { should_not be_valid }
  end
    
  describe "when email address has mixed case" do
    let(:mixed_case_email) { "Foo@ExAMPle.CoM" }
    before do
      user.email = mixed_case_email
      user.email_confirmation = mixed_case_email
      user.save
    end
    specify { expect(user.email).to eq(mixed_case_email.downcase) }
  end
  
  # Password
  describe "when password is not present" do
    before { user.password = user.password_confirmation = " " }
    it { should_not be_valid }
  end
    
  describe "when password does not match confirmation" do
    before { user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end
    
  describe "when password confirmation is nil" do
    before { user.password_confirmation = nil }
    it { should_not be_valid }
  end
  
  describe "when password is too short" do
    before { user.password = user.password_confirmation = "a" * 7 }
    it { should be_invalid }
  end
    
  describe "return value of authenticate method" do
    before { user.save }
    let(:found_user) { User.find_by_email(user.email) }

    describe "with valid password" do
      specify { expect(found_user.authenticate(user.password)).to eq(user) }
    end

    describe "with invalid password" do
      specify { expect(found_user.authenticate("invalid")).not_to eq(user) }
    end
  end
  
  # Year
  describe "when year is not present" do
    before { user.year = nil }
    it { should_not be_valid }
  end
  
  # Corrector color
  describe "corrector color" do
    before { user.corrector = true }
    
    describe "when color does not start with #" do
      before { user.corrector_color = "022EE33" }
      it { should_not be_valid }
    end
    
    describe "when color is too short" do
      before { user.corrector_color = "#013F5" }
      it { should_not be_valid }
    end
     
    describe "when color is too long" do
      before { user.corrector_color = "#AABBCCD" }
      it { should_not be_valid }
    end
     
    describe "when color contains unwanted letter" do
      before { user.corrector_color = "#BCDEFG" }
      it { should_not be_valid }
    end
    
    describe "when color is correct" do
      before { user.corrector_color = "#789DEF" }
      it { should be_valid }
    end
    
    describe "when color contains lower case letters" do
      before { user.corrector_color = "#abcde8" }
      it { should be_valid }
    end
  end
  
  # Colored and linked names
  describe "colored names" do
    before do
      user.first_name = "Jean"
      user.last_name = "Dupont"
      user.save
    end
    
    describe "for an admin" do
      before { user.update_attribute(:role, :administrator) }
      specify do
        expect(user.colored_name).to eq("<span class='text-color-black-white fw-bold'>Jean Dupont</span>")
        expect(user.linked_name(0, false)).to eq("<a href='#{user_path(user)}' class='text-color-black-white'>" + user.colored_name + "</a>")
      end
    end
    
    describe "for a deleted user" do
      before do
        user.first_name = "Compte"
        user.last_name = "supprimé"
        user.role = :deleted
        user.save
      end
      specify do
        expect(user.color_class).to eq("text-color-level-inactive")
        expect(user.colored_name).to eq("<span class='fw-bold #{user.color_class}'>Compte supprimé</span>")
        expect(user.linked_name).to eq(user.colored_name)
      end
    end
    
    describe "for a student with some rating" do
      before { Color.create_defaults }
      specify do
        ratings_to_test = [0, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
        ratings_to_test.each do |rating|
          user.update_attribute(:rating, rating)
          c = Color.where("pt <= ?", rating).order("pt").last
          expect(user.level[:id]).to eq(c.id)
          expect(user.color_class).to eq("text-color-level-#{c.id}")
          expect(user.colored_name).to eq("<span class='fw-bold #{user.color_class}'>Jean Dupont</span>")
          expect(user.linked_name).to eq("<a href='#{user_path(user)}' class='#{user.color_class}'>" + user.colored_name + "</a>")
        end
      end
    end
    
    describe "for a student with some rating and see_name = 0" do
      before do
        Color.create_defaults
        user.update_attribute(:see_name, 0)
      end
      specify do
        ratings_to_test = [0, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
        ratings_to_test.each do |rating|
          user.update_attribute(:rating, rating)
          c = Color.where("pt <= ?", rating).order("pt").last
          expect(user.level[:id]).to eq(c.id)
          expect(user.color_class).to eq("text-color-level-#{c.id}")
          expect(user.colored_name).to eq("<span class='fw-bold #{user.color_class}'>Jean D.</span>")
          expect(user.linked_name).to eq("<a href='#{user_path(user)}' class='#{user.color_class}'>" + user.colored_name + "</a>")
        end
      end
    end
    
    describe "for a corrector with some rating" do
      before do
        Color.create_defaults
        user.update_attribute(:corrector, true)
      end
      specify do
        ratings_to_test = [0, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
        (0..8).each do |i|
          rating = ratings_to_test[i]
          level = i
          user.update(:rating => rating, :correction_level => level)
          c = Color.where("pt <= ?", rating).order("pt").last
          expect(user.level[:id]).to eq(c.id)
          expect(user.color_class).to eq("text-color-level-#{c.id}")
          expect(user.colored_name(0, false)).to eq("<span class='text-color-black-white fw-bold'>J</span><span class='fw-bold #{user.color_class}'>ean Dupont</span>")
          expect(user.colored_name).to eq((level == 0 ? "" : "<span class='text-color-black-white fw-bold'><sup>#{level}</sup></span>") + user.colored_name(0, false))
          expect(user.linked_name).to eq((level == 0 ? "" : "<span class='text-color-black-white fw-bold'><sup>#{level}</sup></span>") + "<a href='#{user_path(user)}' class='#{user.color_class}'>" + user.colored_name(0, false) + "</a>")
        end
      end
    end
  end
  
  # can_write_submission?
  describe "can_write_submission?" do
    let!(:important_chapter) { FactoryBot.create(:chapter, online: true, submission_prerequisite: true) }
    let!(:important_chapter_offline) { FactoryBot.create(:chapter, online: false, submission_prerequisite: true) }
    let!(:useless_chapter) { FactoryBot.create(:chapter, online: true) }
    let!(:user1) { FactoryBot.create(:advanced_user) }
    
    describe "when user cannot" do
      before { user1.chapters << useless_chapter }
      specify { expect(user1.can_write_submission?).to eq(false) }
    end
    
    describe "when user can" do
      before { user1.chapters << important_chapter }
      specify { expect(user1.can_write_submission?).to eq(true) }
    end
  end
  
  # has_already_submitted_today?
  describe "has_already_submitted_today?" do
    let!(:user1) { FactoryBot.create(:advanced_user) }
    let!(:time) { DateTime.new(2025, 11, 2, 20, 36, 12) }
    
     describe "when already submitted" do
       let!(:submission) { FactoryBot.create(:submission, user: user1, status: :wrong, created_at: time - 2.hours) }
       before { travel_to time }
       specify { expect(user1.has_already_submitted_today?).to eq(true) }
       after { travel_back }
     end
     
     describe "when not already submitted" do
       let!(:submission_draft) { FactoryBot.create(:submission, user: user1, status: :draft, created_at: time - 2.hours) }
       let!(:submission_old) { FactoryBot.create(:submission, user: user1, status: :correct, created_at: time - 1.day) }
       before { travel_to time }
       specify { expect(user1.has_already_submitted_today?).to eq(false) }
       after { travel_back }
     end
  end
  
  describe "pb_solved? and chap_solved?" do
    let!(:user1) { FactoryBot.create(:advanced_user) }
    let!(:problem) { FactoryBot.create(:problem, online: true) }
    let!(:chapter) { FactoryBot.create(:chapter, online: true) }
    specify do
      expect(user1.pb_solved?(problem)).to eq(false)
      expect(user1.chap_solved?(chapter)).to eq(false)
    end
    
    describe "when they were solved" do
      let!(:sp) { FactoryBot.create(:solvedproblem, problem: problem, user: user1) }
      before { user1.chapters << chapter }
      specify do
        expect(user1.pb_solved?(problem)).to eq(true)
        expect(user1.chap_solved?(chapter)).to eq(true)
      end
    end
  end
  
  # test_status
  describe "test_status" do
    let!(:user1) { FactoryBot.create(:advanced_user) }
    let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true) }
    
    describe "when test was not started" do
      specify { expect(user1.test_status(virtualtest)).to eq("not_started") }
    end
    
    describe "when test was started" do
      let!(:takentest) { Takentest.create(virtualtest: virtualtest, user: user1, taken_time: DateTime.now - 2.hours, status: :in_progress) }
      specify { expect(user1.test_status(virtualtest)).to eq("in_progress") }
    end
    
    describe "when test was finished" do
      let!(:takentest) { Takentest.create(virtualtest: virtualtest, user: user1, taken_time: DateTime.now - 5.hours, status: :finished) }
      specify { expect(user1.test_status(virtualtest)).to eq("finished") }
    end
  end
  
  # num_notifications_new
  describe "num_notifications_new" do
    before { Submission.destroy_all } # Not sure if needed
    let!(:time) { DateTime.new(2025, 11, 2, 20, 36, 12) }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:corrector) { FactoryBot.create(:corrector) }
    let!(:problem1) { FactoryBot.create(:problem, online: true, level: 1) }
    let!(:problem2) { FactoryBot.create(:problem, online: true, level: 2) }
    let!(:problem3) { FactoryBot.create(:problem, online: true, level: 3) }
    let!(:sp1) { FactoryBot.create(:solvedproblem, problem: problem1, user: corrector) }
    let!(:sp2) { FactoryBot.create(:solvedproblem, problem: problem2, user: corrector) }
    let!(:submission11) { FactoryBot.create(:submission, problem: problem1, status: :waiting, created_at: time - 2.hours) } # today
    let!(:submission12) { FactoryBot.create(:submission, problem: problem1, status: :waiting, created_at: time - 1.day) } # yesterday
    let!(:submission21) { FactoryBot.create(:submission, problem: problem2, status: :waiting, created_at: time - 1.day - 1.hour) } # yesterday
    let!(:submission22) { FactoryBot.create(:submission, problem: problem2, status: :waiting, created_at: time - 2.days) } # two days ago
    let!(:submission31) { FactoryBot.create(:submission, problem: problem3, status: :waiting, created_at: time - 2.days - 1.hour) } # two days ago
    before do
      travel_to time
      corrector.favorite_problems << problem1
      admin.favorite_problems << problem2
    end
    
    specify do
      expect(admin.num_notifications_new([1, 2, 3], true, false)).to eq([5, 0])
      expect(admin.num_notifications_new([1, 2, 3], false, false)).to eq([2, 2])
      expect(admin.num_notifications_new([1, 2, 3], true, true)).to eq([2, 0])
      expect(admin.num_notifications_new([1, 2, 3], false, true)).to eq([2, 1])
      expect(admin.num_notifications_new([1, 2], true, false)).to eq([4, 0])
      expect(admin.num_notifications_new([1, 2], false, false)).to eq([3, 1])
      expect(admin.num_notifications_new([1], true, true)).to eq([0, 0])
      expect(admin.num_notifications_new([1], false, true)).to eq([0, 0])
      
      expect(corrector.num_notifications_new([1, 2, 3], true, false)).to eq([4, 0])
      expect(corrector.num_notifications_new([1, 2, 3], false, false)).to eq([3, 1])
      expect(corrector.num_notifications_new([1, 2, 3], true, true)).to eq([2, 0])
      expect(corrector.num_notifications_new([1, 2, 3], false, true)).to eq([2, 0])
      expect(corrector.num_notifications_new([1], true, false)).to eq([2, 0])
      expect(corrector.num_notifications_new([1], false, false)).to eq([2, 0])
      expect(corrector.num_notifications_new([1], true, true)).to eq([2, 0])
      expect(corrector.num_notifications_new([1], false, true)).to eq([2, 0])
    end
    
    after { travel_back }
  end
  
  # adapt_name    
  describe "adapt_name when last_name has leading and trailing white spaces" do
    before do
      user.last_name = "  Dupont   "
      user.adapt_name
    end
    specify { expect(user.last_name).to eq("Dupont") }
  end
    
  describe "adapt_name when last_name has only one letter" do
    before do
      user.last_name = "  D   "
      user.adapt_name
    end
    specify { expect(user.last_name).to eq("D.") } # The point should be added
  end
  
  # num_unseen_subjects
  describe "number of unseen forum subjects" do
    let!(:user_normal)           { FactoryBot.create(:user,  last_forum_visit_time: DateTime.now - 3.days) }
    let!(:user_wepion)           { FactoryBot.create(:user,  last_forum_visit_time: DateTime.now - 3.days, wepion: true) }
    let!(:user_corrector)        { FactoryBot.create(:user,  last_forum_visit_time: DateTime.now - 3.days, corrector: true) }
    let!(:user_wepion_corrector) { FactoryBot.create(:user,  last_forum_visit_time: DateTime.now - 3.days, wepion: true, corrector: true) }
    let!(:user_admin)            { FactoryBot.create(:admin, last_forum_visit_time: DateTime.now - 3.days) }
    
    let!(:subject)            { FactoryBot.create(:subject, last_comment_time: DateTime.now - 1.day, last_comment_user: user_normal) }
    let!(:subject_wepion)     { FactoryBot.create(:subject, last_comment_time: DateTime.now - 1.day, last_comment_user: user_wepion, for_wepion: true) }
    let!(:subject_correctors) { FactoryBot.create(:subject, last_comment_time: DateTime.now - 1.day, last_comment_user: user_admin, for_correctors: true) }
    
    describe "when all subjects are new" do
      specify do
        expect(user_normal.num_unseen_subjects(true)).to eq(1)
        expect(user_wepion.num_unseen_subjects(true)).to eq(2)
        expect(user_corrector.num_unseen_subjects(true)).to eq(2)
        expect(user_wepion_corrector.num_unseen_subjects(true)).to eq(3)
        expect(user_admin.num_unseen_subjects(true)).to eq(3)
        
        expect(user_normal.num_unseen_subjects(false)).to eq(0) # One subject less
        expect(user_wepion.num_unseen_subjects(false)).to eq(1) # One subject less
        expect(user_corrector.num_unseen_subjects(false)).to eq(2)
        expect(user_wepion_corrector.num_unseen_subjects(false)).to eq(3)
        expect(user_admin.num_unseen_subjects(false)).to eq(2) # One subject less
      end
    end
    
    describe "when all subjects are older" do
      before do
        subject.update_attribute(:last_comment_time, DateTime.now - 4.days)
        subject_wepion.update_attribute(:last_comment_time, DateTime.now - 4.days)
        subject_correctors.update_attribute(:last_comment_time, DateTime.now - 4.days)
      end
      
      specify do
        expect(user_normal.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion.num_unseen_subjects(true)).to eq(0)
        expect(user_corrector.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(true)).to eq(0)
        expect(user_admin.num_unseen_subjects(true)).to eq(0)
        
        expect(user_normal.num_unseen_subjects(false)).to eq(0)
        expect(user_wepion.num_unseen_subjects(false)).to eq(0)
        expect(user_corrector.num_unseen_subjects(false)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(false)).to eq(0)
        expect(user_admin.num_unseen_subjects(false)).to eq(0)
      end
    end
    
    describe "when some subjects are older" do
      before do
        subject.update_attribute(:last_comment_time, DateTime.now - 4.days)
        subject_wepion.update_attribute(:last_comment_time, DateTime.now - 1.days)
        subject_correctors.update_attribute(:last_comment_time, DateTime.now - 4.days)
      end
      
      specify do
        expect(user_normal.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion.num_unseen_subjects(true)).to eq(1)
        expect(user_corrector.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(true)).to eq(1)
        expect(user_admin.num_unseen_subjects(true)).to eq(1)
        
        expect(user_normal.num_unseen_subjects(false)).to eq(0)
        expect(user_wepion.num_unseen_subjects(false)).to eq(0)
        expect(user_corrector.num_unseen_subjects(false)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(false)).to eq(1)
        expect(user_admin.num_unseen_subjects(false)).to eq(1)
      end
    end
  end
  
  # delete_unconfirmed
  describe "delete_unconfirmed" do
    let!(:zero_user) { FactoryBot.create(:user, rating: 0) }
    let!(:other_zero_user) { FactoryBot.create(:user, rating: 0) }
    describe "for user with unconfirmed email for a long time" do
      before do
        zero_user.update(:email_confirm => false,
                         :created_at => DateTime.now - 8.days)
        other_zero_user.update(:email_confirm => false,
                               :created_at => DateTime.now - 6.days)
      end
      specify { expect { User.delete_unconfirmed }.to change(User, :count).by(-1) } # Only zero_user should be deleted
    end
    
    describe "deletes user that never came for one month" do
      let!(:other_zero_user2) { FactoryBot.create(:user, rating: 0) }
      before do
        zero_user.update(:created_at => DateTime.now - 40.days,
                         :last_connexion_date => "2009-01-01")
        other_zero_user.update(:created_at => DateTime.now - 20.days,
                               :last_connexion_date => "2009-01-01")
        other_zero_user2.update(:created_at => DateTime.now - 40.days,
                                :last_connexion_date => "2020-01-01")
      end
      specify { expect { User.delete_unconfirmed }.to change(User, :count).by(-1) } # Only zero_user should be deleted
    end
  end
  
  # last_sanction_of_type, has_sanction_of_type
  describe "last_sanction_of_type and has_sanction_of_type" do
    let!(:user1) { FactoryBot.create(:user) }
    
    describe "when there is no sanction" do
      specify do
        expect(user1.last_sanction_of_type(:ban)).to eq(nil)
        expect(user1.last_sanction_of_type(:no_submission)).to eq(nil)
        expect(user1.last_sanction_of_type(:not_corrected)).to eq(nil)
        expect(user1.has_sanction_of_type(:ban)).to eq(false)
        expect(user1.has_sanction_of_type(:no_submission)).to eq(false)
        expect(user1.has_sanction_of_type(:not_corrected)).to eq(false)
      end
    end
    
    describe "when there is an old and a recent sanction" do
      let!(:sanction1) { FactoryBot.create(:sanction, user: user1, sanction_type: :ban, start_time: DateTime.now - 26.days, duration: 14) }
      let!(:sanction2) { FactoryBot.create(:sanction, user: user1, sanction_type: :ban, start_time: DateTime.now - 4.days, duration: 14) }
      specify do
        expect(user1.last_sanction_of_type(:ban)).to eq(sanction2)
        expect(user1.has_sanction_of_type(:ban)).to eq(true)
      end
    end
    
    describe "when there is only an old sanction" do
      let!(:sanction) { FactoryBot.create(:sanction, user: user1, sanction_type: :no_submission, start_time: DateTime.now - 32.days, duration: 30) }
      specify do
        expect(user1.last_sanction_of_type(:no_submission)).to eq(sanction)
        expect(user1.has_sanction_of_type(:no_submission)).to eq(false)
      end
    end
  end
  
  # update_remember_token
  describe "update_remember_token" do
    let!(:user1) { FactoryBot.create(:user) }
    let!(:old_token) { user1.remember_token }
    before { user1.update_remember_token }
    specify { expect(user1.remember_token).not_to eq(old_token) }
  end
  
  # get_threshold_of_correction_level and compute_correction_level
  describe "get_threshold_of_correction_level and compute_correction_level" do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }
    specify do
      expect(User.compute_correction_level(54)).to eq(0)
      expect(User.get_threshold_of_correction_level(1)).to eq(55)
      expect(User.compute_correction_level(55)).to eq(1)
      expect(User.compute_correction_level(88)).to eq(1)
      expect(User.get_threshold_of_correction_level(2)).to eq(89)
      expect(User.compute_correction_level(89)).to eq(2)
      expect(User.compute_correction_level(143)).to eq(2)
      expect(User.get_threshold_of_correction_level(3)).to eq(144)
      expect(User.compute_correction_level(144)).to eq(3)
      expect(User.compute_correction_level(27117)).to eq(13)
      expect(User.get_threshold_of_correction_level(14)).to eq(28657)
    end
    after { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test")) }
  end
  
  # update_correction_level
  describe "update_correction_level" do
    let!(:corrector) { FactoryBot.create(:corrector) }
    before do
      (1..10).each do |i|
        FactoryBot.create(:following, user: corrector)
      end
      corrector.update_correction_level
    end
    specify { expect(corrector.correction_level).to eq(4) } # 10 corrections = level 4 in test environment
  end
  
  # recompute_scores
  describe "recompute_scores" do
    let!(:user1) { FactoryBot.create(:user) }
    let!(:section) { FactoryBot.create(:section, :fondation => false) }
    let!(:section2) { FactoryBot.create(:section, :fondation => false) }
    let!(:section_fondation) { FactoryBot.create(:section, :fondation => true) }
    let!(:chapter) { FactoryBot.create(:chapter, :section => section, :online => true) }
    let!(:chapter_fondation) { FactoryBot.create(:chapter, :section => section_fondation, :online => true) }
    let!(:question) { FactoryBot.create(:exercise, :chapter => chapter, :level => 2, :online => true) }
    let!(:question2) { FactoryBot.create(:exercise, :chapter => chapter, :level => 3, :online => true) }
    let!(:question_fondation) { FactoryBot.create(:exercise, :chapter => chapter_fondation, :level => 4, :online => true) }
    let!(:problem) { FactoryBot.create(:problem, :section => section2, :level => 4, :online => true) }
    let!(:problem_offline) { FactoryBot.create(:problem, :section => section, :level => 5, :online => false) }
    let!(:submission) { FactoryBot.create(:submission, :problem => problem, :user => user1, :status => "correct") }
    let!(:solvedproblem) { FactoryBot.create(:solvedproblem, :problem => problem, :user => user1, :submission => submission) }
    let!(:solvedquestion) { FactoryBot.create(:solvedquestion, :question => question, :user => user1) }
    let!(:unsolvedquestion) { FactoryBot.create(:unsolvedquestion, :question => question2, :user => user1) }
    let!(:solvedquestion_fondation) { FactoryBot.create(:solvedquestion, :question => question_fondation, :user => user1) }
    let!(:pointspersection) { Pointspersection.create(:user => user1, :section => section, :points => 0) }
    let!(:pointspersection2) { Pointspersection.create(:user => user1, :section => section2, :points => 0) }
    
    before do
      User.recompute_scores(false)
      user1.reload
      section.reload
      section2.reload
    end
    specify do
      expect(user1.rating).to eq(problem.value + question.value)
      expect(section.max_score).to eq(question.value + question2.value)
      expect(section2.max_score).to eq(problem.value)
      expect(user1.pointspersections.where(:section => section).first.points).to eq(question.value)
      expect(user1.pointspersections.where(:section => section2).first.points).to eq(problem.value)
    end
  end
end
