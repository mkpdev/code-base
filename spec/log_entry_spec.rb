require 'spec_helper'

describe LogEntry do
  it { should belong_to(:user) }
  it { should belong_to(:loggable) }
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:loggable) }

  describe "Ensuring a timecode saves as seconds" do
    it "#convert_time_code_to_seconds after saving" do
      log_entry = FactoryGirl.create(:log_entry)
      log_entry.duration = "02:30:59"
      lambda {
        log_entry.save
      }.should change(log_entry, :duration).from("02:30:59").to(9059)
    end
  end

  describe "Keeping measurements in sync" do
    let(:log_entry) {FactoryGirl.build(:log_entry)}

    it "give a default for a measurement" do
      log_entry.distance = 500
      log_entry.default_or_present_measurement("yards")
      log_entry.save
      log_entry.measurement.should eql("yards")
    end

    it "should not use a default measurement if one already exists" do
      log_entry.distance = 500
      log_entry.measurement = "kilometers"
      log_entry.default_or_present_measurement("yards")
      log_entry.save
      log_entry.measurement.should eql("kilometers")
    end
  end
end

describe "Scopes" do
  it "should return log_entries for a date" do
    log_entry_today = FactoryGirl.create(:log_entry)
    log_entry_yesterday = FactoryGirl.create(:log_entry, created_at: Date.yesterday)
    LogEntry.for_date(Time.zone.today).should include(log_entry_today)
    LogEntry.for_date(Time.zone.today).should_not include(log_entry_yesterday)
  end

  it "should return log entries for a given period" do
    log_entry_today = FactoryGirl.create(:log_entry)
    log_entry_yesterday = FactoryGirl.create(:log_entry, created_at: Date.yesterday)
    log_entry_4_days_ago = FactoryGirl.create(:log_entry, created_at: 4.days.ago)
    log_entry_7_days_ago = FactoryGirl.create(:log_entry, created_at: 7.days.ago)
    log_entry_1_week_ago = FactoryGirl.create(:log_entry, created_at: 1.week.ago)
    log_entry_1_month_ago = FactoryGirl.create(:log_entry, created_at: 1.month.ago)
    log_entry_2_months_ago = FactoryGirl.create(:log_entry, created_at: 2.months.ago)
    LogEntry.for_period(4.days.ago, Time.zone.today).should include(log_entry_yesterday)
    LogEntry.for_period(4.days.ago, Time.zone.today).should include(log_entry_4_days_ago)
    LogEntry.for_period(4.days.ago, Time.zone.today).should_not include(log_entry_1_week_ago)
    LogEntry.for_period(1.month.ago, Time.zone.today).should_not include(log_entry_2_months_ago)
    LogEntry.for_period(1.month.ago, Time.zone.today).should include(log_entry_1_month_ago)
  end
end
