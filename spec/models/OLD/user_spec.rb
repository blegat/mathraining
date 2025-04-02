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

describe User do

  before { @user = FactoryGirl.build(:user) }

  subject { @user }

  it do
    should respond_to(:first_name)
    should respond_to(:last_name)
    should respond_to(:email)
    should respond_to(:password_digest)
    should respond_to(:password)
    should respond_to(:password_confirmation)
    should respond_to(:remember_token)
    should respond_to(:authenticate)

    should be_valid
  end
  
  describe "name, password and email" do

    describe "when first_name is not present" do
      before { @user.first_name = " " }
      it { should_not be_valid }
    end
    
    describe "when last_name is not present" do
      before { @user.last_name = " " }
      it { should_not be_valid }
    end
    
    describe "when first_name is too long" do
      before { @user.first_name = "a" * 33 }
      it { should_not be_valid }
    end
    
    describe "when last_name is too long" do
      before { @user.last_name = "a" * 33 }
      it { should_not be_valid }
    end
    
    describe "when first_name contains a digit" do
      before { @user.first_name = "Henri-27" }
      it { should_not be_valid }
    end
    
    describe "when last_name has leading and trailing white spaces" do
      before do
        @user.last_name = "  Dupont   "
        @user.adapt_name
      end
      it do
        expect(@user.last_name).to eq("Dupont")
      end
    end
    
    describe "when last_name has only one letter" do
      before do
        @user.last_name = "  D   "
        @user.adapt_name
      end
      it do
        expect(@user.last_name).to eq("D.") # The point should be added
      end
    end
    
    describe "uses name, shortname, fullname" do
      before do
        @user.first_name = "Jean"
        @user.last_name = "Dupont"
        @user.save
      end
      it do
        expect(@user.name).to eq("Jean Dupont")
        expect(@user.fullname).to eq("Jean Dupont")
        expect(@user.shortname).to eq("Jean D.")
      end
      
      describe "when see_name = 0" do
        before do
          @user.see_name = 0
          @user.save
        end
        it do
          expect(@user.name).to eq("Jean D.")
          expect(@user.fullname).to eq("Jean Dupont")
          expect(@user.shortname).to eq("Jean D.")
        end
      end
    end
    
    describe "when email is not present" do
      before { @user.email = " " }
      it { should_not be_valid }
    end

    describe "when email format is invalid" do
      it "should be invalid" do
        addresses = %w[user@foo,com user_at_foo.org example.user@foo.foo@bar_baz.com foo@bar+baz.com]
        addresses.each do |invalid_address|
        	@user.email = invalid_address
        	@user.email_confirmation = invalid_address
        	expect(@user).not_to be_valid
        end
      end
    end

    describe "when email format is valid" do
      it "should be valid" do
        addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
        addresses.each do |valid_address|
          @user.email = valid_address
          @user.email_confirmation = valid_address
          expect(@user).to be_valid
        end
      end
    end
    
    describe "when email address is already taken" do
      before do
        user_with_same_email = @user.dup
        user_with_same_email.email = user_with_same_email.email.upcase
        user_with_same_email.email_confirmation = user_with_same_email.email
        user_with_same_email.save
      end
      it { should_not be_valid }
    end
    
    describe "when email address has mixed case" do
      let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

      it "should be saved as all lower-case" do
        @user.email = mixed_case_email
        @user.email_confirmation = mixed_case_email
        @user.save
        expect(@user.email).to eq(mixed_case_email.downcase)
      end
    end
    
    describe "when password is not present" do
      before { @user.password = @user.password_confirmation = " " }
      it { should_not be_valid }
    end
    
    describe "when password does not match confirmation" do
      before { @user.password_confirmation = "mismatch" }
      it { should_not be_valid }
    end
    
    describe "when password confirmation is nil" do
      before { @user.password_confirmation = nil }
      it { should_not be_valid }
    end
    
    describe "return value of authenticate method" do
      before { @user.save }
      let(:found_user) { User.find_by_email(@user.email) }

      describe "with valid password" do
        it { should == found_user.authenticate(@user.password) }
      end

      describe "with invalid password" do
        it { should_not == found_user.authenticate("invalid") }
      end
    end
    
    describe "with a password that is too short" do
      before { @user.password = @user.password_confirmation = "a" * 5 }
      it { should be_invalid }
    end
  end
  
  describe "corrector color" do
    before { @user.corrector = true }
    
    describe "when color does not start with #" do
      before { @user.corrector_color = "022EE33" }
      it { should_not be_valid }
    end
    
    describe "when color is too short" do
      before { @user.corrector_color = "#013F5" }
      it { should_not be_valid }
    end
     
    describe "when color is too long" do
      before { @user.corrector_color = "#AABBCCD" }
      it { should_not be_valid }
    end
     
    describe "when color contains unwanted letter" do
      before { @user.corrector_color = "#BCDEFG" }
      it { should_not be_valid }
    end
    
    describe "when color is correct" do
      before { @user.corrector_color = "#789DEF" }
      it { should be_valid }
    end
    
    describe "when color contains lower case letters" do
      before { @user.corrector_color = "#abcde8" }
      it { should be_valid }
    end
  end
  
  describe "colored names" do
    before do
      @user.first_name = "Jean"
      @user.last_name = "Dupont"
      @user.save
    end
    
    describe "for an admin" do
      before { @user.update_attribute(:role, :administrator) }
      it do
        expect(@user.colored_name).to eq("<span class='text-color-black-white fw-bold'>Jean Dupont</span>")
        expect(@user.linked_name(0, false)).to eq("<a href='#{user_path(@user)}' class='text-color-black-white'>" + @user.colored_name + "</a>")
      end
    end
    
    describe "for a deleted user" do
      before do
        @user.first_name = "Compte"
        @user.last_name = "supprimé"
        @user.role = :deleted
        @user.save
      end
      it do
        expect(@user.color_class).to eq("text-color-level-inactive")
        expect(@user.colored_name).to eq("<span class='fw-bold #{@user.color_class}'>Compte supprimé</span>")
        expect(@user.linked_name).to eq(@user.colored_name)
      end
    end
    
    describe "for a student with some rating" do
      before { Color.create_defaults }
      it "should have correct color" do
        ratings_to_test = [0, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
        ratings_to_test.each do |rating|
          @user.update_attribute(:rating, rating)
          c = Color.where("pt <= ?", rating).order("pt").last
          expect(@user.level[:id]).to eq(c.id)
          expect(@user.color_class).to eq("text-color-level-#{c.id}")
          expect(@user.colored_name).to eq("<span class='fw-bold #{@user.color_class}'>Jean Dupont</span>")
          expect(@user.linked_name).to eq("<a href='#{user_path(@user)}' class='#{@user.color_class}'>" + @user.colored_name + "</a>")
        end
      end
    end
    
    describe "for a student with some rating and see_name = 0" do
      before do
        Color.create_defaults
        @user.update_attribute(:see_name, 0)
      end
      it "should have correct color" do
        ratings_to_test = [0, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
        ratings_to_test.each do |rating|
          @user.update_attribute(:rating, rating)
          c = Color.where("pt <= ?", rating).order("pt").last
          expect(@user.level[:id]).to eq(c.id)
          expect(@user.color_class).to eq("text-color-level-#{c.id}")
          expect(@user.colored_name).to eq("<span class='fw-bold #{@user.color_class}'>Jean D.</span>")
          expect(@user.linked_name).to eq("<a href='#{user_path(@user)}' class='#{@user.color_class}'>" + @user.colored_name + "</a>")
        end
      end
    end
    
    describe "for a corrector with some rating" do
      before do
        Color.create_defaults
        @user.update_attribute(:corrector, true)
      end
      it "should have correct color" do
        ratings_to_test = [0, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
        ratings_to_test.each do |rating|
          @user.update_attribute(:rating, rating)
          c = Color.where("pt <= ?", rating).order("pt").last
          expect(@user.level[:id]).to eq(c.id)
          expect(@user.color_class).to eq("text-color-level-#{c.id}")
          expect(@user.colored_name).to eq("<span class='text-color-black-white fw-bold'>J</span><span class='fw-bold #{@user.color_class}'>ean Dupont</span>")
          expect(@user.linked_name).to eq("<a href='#{user_path(@user)}' class='#{@user.color_class}'>" + @user.colored_name + "</a>")
        end
      end
    end
  end
  
  describe "number of unseen forum subjects" do
    let!(:user) {                  FactoryGirl.create(:user,  last_forum_visit_time: DateTime.now - 3.days) }
    let!(:user_wepion) {           FactoryGirl.create(:user,  last_forum_visit_time: DateTime.now - 3.days, wepion: true) }
    let!(:user_corrector) {        FactoryGirl.create(:user,  last_forum_visit_time: DateTime.now - 3.days, corrector: true) }
    let!(:user_wepion_corrector) { FactoryGirl.create(:user,  last_forum_visit_time: DateTime.now - 3.days, wepion: true, corrector: true) }
    let!(:user_admin) {            FactoryGirl.create(:admin, last_forum_visit_time: DateTime.now - 3.days) }
    
    let!(:subject)            { FactoryGirl.create(:subject, last_comment_time: DateTime.now - 1.day, last_comment_user: user) }
    let!(:subject_wepion)     { FactoryGirl.create(:subject, last_comment_time: DateTime.now - 1.day, last_comment_user: user_wepion, for_wepion: true) }
    let!(:subject_correctors) { FactoryGirl.create(:subject, last_comment_time: DateTime.now - 1.day, last_comment_user: user_admin, for_correctors: true) }
    
    describe "when all subjects are new" do
      it do
        expect(user.num_unseen_subjects(true)).to eq(1)
        expect(user_wepion.num_unseen_subjects(true)).to eq(2)
        expect(user_corrector.num_unseen_subjects(true)).to eq(2)
        expect(user_wepion_corrector.num_unseen_subjects(true)).to eq(3)
        expect(user_admin.num_unseen_subjects(true)).to eq(3)
        
        expect(user.num_unseen_subjects(false)).to eq(0) # One subject less
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
      
      it do
        expect(user.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion.num_unseen_subjects(true)).to eq(0)
        expect(user_corrector.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(true)).to eq(0)
        expect(user_admin.num_unseen_subjects(true)).to eq(0)
        
        expect(user.num_unseen_subjects(false)).to eq(0)
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
      
      it do
        expect(user.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion.num_unseen_subjects(true)).to eq(1)
        expect(user_corrector.num_unseen_subjects(true)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(true)).to eq(1)
        expect(user_admin.num_unseen_subjects(true)).to eq(1)
        
        expect(user.num_unseen_subjects(false)).to eq(0)
        expect(user_wepion.num_unseen_subjects(false)).to eq(0)
        expect(user_corrector.num_unseen_subjects(false)).to eq(0)
        expect(user_wepion_corrector.num_unseen_subjects(false)).to eq(1)
        expect(user_admin.num_unseen_subjects(false)).to eq(1)
      end
    end
  end
end
