require 'spec_helper'

describe Exercise do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:exercise_category) }
  it { should belong_to(:exercise_category) }
  it { should have_many(:log_entries) }
  it { should have_many(:workouts) }
  it { should have_many(:exercise_workouts) }

  let(:exercise) { create(:exercise) }
  let(:user) { create(:user) }

  describe "#custom?" do
    it "returns true if user_id is present" do
      subject.stub(:user_id).and_return(1)
      expect(subject.custom?).to be_true
    end

    it "returns false if user_id is not present" do
      expect(subject.custom?).to be_false
    end
  end

  describe "#last_placeholder_log_date" do
    let!(:log_entry) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let!(:placeholder_log_entry) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago, placeholder: true, weight: nil, reps: nil) }

    subject { exercise }

    it "returns the last log date specifically for a log entry labeled as a placeholder" do
      expect(subject.last_placeholder_log_date(user)).to eql placeholder_log_entry.created_at.beginning_of_day
    end

    context "no log date for that exercise" do

      before do
        subject.stub(:last_log_entry).and_return(nil)
      end

      it "returns false" do
        expect(subject.last_placeholder_log_date(user)).to be_nil
      end
    end

  end

  describe "#last_log_date" do
    let!(:log_entry) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let!(:log_entry_month) { create(:log_entry, loggable: exercise, user: user, created_at: 1.month.ago) }
    let!(:log_entry_year) { create(:log_entry, loggable: exercise, user: user, created_at: 1.year.ago) }

    subject { exercise }

    it "returns the last date a user performed the exercise" do
      subject.last_log_date(user).should eql 1.week.ago.beginning_of_day
    end
  end

  describe "#placeholder_log_entries" do
    let!(:placeholder_log_entry_1) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let!(:placeholder_log_entry_2) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let!(:placeholder_log_entry_3) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let!(:placeholder_log_entry_nope) { create(:log_entry, loggable: exercise, user: user, created_at: 3.weeks.ago, placeholder: true, weight: nil, reps: nil) }
    let!(:placeholder_log_entry_nope_nope) { create(:log_entry, loggable: exercise, user: user, created_at: 3.weeks.ago, placeholder: true, weight: nil, reps: nil) }

    subject { exercise }

    before do
      subject.create_placeholder_log_entries(user)
    end

    it "returns a list of log entries that are meant for placeholders" do
      expect(subject.placeholder_log_entries(user).size).should eql 3
    end
  end

  describe "#create_placeholder_log_entries" do
    let!(:placeholder_log_entry_1) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago, distance: 5, duration: '5:00:00') }
    let!(:placeholder_log_entry_2) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let!(:placeholder_log_entry_3) { create(:log_entry, loggable: exercise, user: user, created_at: 1.week.ago) }
    let(:log_entries) { subject.placeholder_log_entries(user) }

    subject { exercise }

    before do
      subject.create_placeholder_log_entries(user)
    end

    it "creates a log entry flagged as placeholder" do
      expect(log_entries.first.placeholder?).to be_true
    end

    it "assigns the right user" do
      expect(log_entries.first.user).to eql user
    end

    it "assigns the right exercise" do
      expect(log_entries.first.loggable).to eql subject
    end

    it "assigns a placeholder weight" do
      expect(log_entries.first.placeholder_weight).to eql placeholder_log_entry_1.weight.to_i
    end

    it "assigns placeholder reps" do
      expect(log_entries.first.placeholder_reps).to eql placeholder_log_entry_1.reps
    end

    it "assigns a placeholder distance" do
      expect(log_entries.first.placeholder_distance).to eql placeholder_log_entry_1.distance
    end

    it "assigns placeholder duration" do
      expect(log_entries.first.placeholder_duration).to eql placeholder_log_entry_1.duration.to_s
    end
  end
end

describe "Returning arrays for graphs" do
  before(:each) do
    @user = FactoryGirl.create(:user)
    @exercise = FactoryGirl.create(:exercise)
    @log_entry_1 = FactoryGirl.build(:log_entry, user: @user, reps: 10, weight: 20)
    @log_entry_2 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 15)
    @log_entry_3 = FactoryGirl.build(:log_entry, user: @user, reps: 10, weight: 10)
    @exercise.log_entries << [@log_entry_1, @log_entry_2, @log_entry_3] 
    @exercise.save
  end

  describe "Total weight lifted" do
    it "Should return the total weight lifted for a day" do
      @exercise.total_weight_lifted_for(Time.zone.today).should eql(45)
    end

    it "Should return the total weight lifted for a user and a given period for each day" do
      log_entry4 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 1.day.ago)
      log_entry5 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 2.days.ago)
      log_entry6 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 2.days.ago)
      @exercise.log_entries << [log_entry4, log_entry5, log_entry6]

      @exercise.user_total_weight_lifted_for_each_day(@user).should eql([
          [@log_entry_1.created_at.to_s(:day_eth), 45],
          [log_entry4.created_at.to_s(:day_eth), 10],
          [log_entry6.created_at.to_s(:day_eth), 20]
        ]
      )
    end

    it "should return the total weight lifted for a user and a given time period for each day" do
      log_entry4 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 1.day.ago)
      log_entry5 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 2.days.ago)
      log_entry6 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 2.days.ago)
      log_entry7 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 40.days.ago)
      @exercise.log_entries << [log_entry4, log_entry5, log_entry6]

      @exercise.user_total_weight_lifted_for_each_day(@user, 30.days.ago, Time.zone.today).should eql([
          [@log_entry_1.created_at.to_s(:day_eth), 45],
          [log_entry4.created_at.to_s(:day_eth), 10],
          [log_entry6.created_at.to_s(:day_eth), 20]
        ]
      )
    end
  end

  describe "Total reps lifted" do
    it "Should return the total reps lifted for a day" do
      @exercise.total_reps_lifted_for(Time.zone.today).should eql(25)
    end

    it "should return the total reps lifted for a user" do
      log_entry4 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 1.day.ago)
      log_entry5 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 2.days.ago)
      log_entry6 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 2.days.ago)
      @exercise.log_entries << [log_entry4, log_entry5, log_entry6]

      @exercise.user_total_reps_lifted_for_each_day(@user).should eql([
        [@log_entry_1.created_at.to_s(:day_eth), 25],
        [log_entry4.created_at.to_s(:day_eth), 5],
        [log_entry5.created_at.to_s(:day_eth), 10],
      ])
    end
  end

  describe "Maximum weight lifted" do
    it "Should return the highest weight lifted for a day" do
      @exercise.maximum_weight_lifted_for(Time.zone.today).should eql(20)
    end

    it "should return the maximum weight lifted for a user" do
      log_entry4 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 10, created_at: 1.day.ago)
      log_entry5 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 20, created_at: 2.days.ago)
      log_entry6 = FactoryGirl.build(:log_entry, user: @user, reps: 5, weight: 30, created_at: 2.days.ago)
      @exercise.log_entries << [log_entry4, log_entry5, log_entry6]

      @exercise.user_maximum_weight_lifted_for_each_day(@user).should eql([
        [@log_entry_1.created_at.to_s(:day_eth), 20],
        [log_entry4.created_at.to_s(:day_eth), 10],
        [log_entry5.created_at.to_s(:day_eth), 30],
      ])
    end
  end
end
