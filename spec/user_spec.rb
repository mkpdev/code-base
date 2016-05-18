require 'spec_helper'

describe User do
  it { should have_many(:workouts) }
  it { should have_many(:log_entries).dependent(:destroy) }
  it { should have_and_belong_to_many(:trainers).class_name('User')}
  it { should_not have_many(:trainer_users) }
  it { should have_and_belong_to_many(:clients).class_name('User') }
  it { should_not have_many(:client_users) }
  it { should have_many(:appointments) }
  it { should have_many(:goals).dependent(:destroy) }
  it { should have_many(:scheduled_workouts).dependent(:destroy) }
  it { should_not allow_mass_assignment_of(:trainer) }

  context "When adding a trainer to a user" do
    let(:trainer) { FactoryGirl.create(:user) }
    let(:client) { FactoryGirl.create(:user) }
    let(:plan) { Plan.first      } 
    let(:card) { valid_card_data } 
    let(:subscription) { FactoryGirl.build :subscription, user: trainer }

    before(:each) do
      subscription.create_stripe_customer
      subscription.update_card card
      subscription.change_plan_to plan
    end

    it "should only allow users to add trainers that are in fact trainers" do
      not_a_real_trainer = FactoryGirl.create(:user)
      client.add_trainer(not_a_real_trainer).should be_false
    end

    it "a user should know if a trainer is in fact their trainer" do
      client.add_trainer(trainer)
      client.is_a_client_of?(trainer).should be_true
    end

    it "should know if the trainer they added is in fact their trainer" do
      client.add_trainer(trainer)
      trainer.reload.is_a_trainer_of?(client).should be_true
    end

    it "shouldn't allow a user to add a trainer twice" do
      client.add_trainer(trainer)
      expect { client.add_trainer(trainer) }.to raise_error
    end

    context "#remove_client" do
      before do
        create(:appointment, trainer: trainer, user: client)
        trainer.remove_client(client)
      end

      it "should remove client from array" do
        expect(trainer.clients).to_not include(client)
      end

      it "should remove trainer from array" do
        expect(client.trainers).to_not include(client)
      end

      it "should remove any appointments for that couple" do
        expect(trainer.appointments.for_user(client)).to be_empty
        expect(client.appointments.for_trainer(trainer)).to be_empty
      end
    end
  end

  describe "Finding out what exercises a user has performed" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @bench_press = FactoryGirl.create(:exercise, name: 'Bench Press')
      @dips = FactoryGirl.create(:exercise, name: 'Dip')
      @squat = FactoryGirl.create(:exercise, name: 'Squat')
      @log_entry = FactoryGirl.create(:log_entry, user: @user, loggable: @bench_press)
      @log_entry2 = FactoryGirl.create(:log_entry, user: @user, loggable: @dips)
      @log_entry3 = FactoryGirl.create(:log_entry, user: @user, loggable: @dips)
    end

    it "Returns a list of exercises" do
      @user.exercises_attempted.should eql([@bench_press, @dips])
    end
  end

  describe "#client_slots_consumed_percentage" do
    let(:user) { FactoryGirl.create :user }

    it "Should give a percentage of available client slots" do
      user.clients.stub(:size).and_return(5)
      user.stub(:plan).and_return(FactoryGirl.create :plan, client_slots: 10)
      user.client_slots_consumed_percentage.should == 50
    end
  end

  describe "#invite_client" do
    let(:trainer) { create(:trainer) }

    before do
      trainer.stub(:trainer?).and_return(true)
    end

    subject { trainer.invite_client("someclient@example.com") }

    it "creates a temporary password" do
      expect(subject.temporary_password).to_not be_nil
      expect(subject.password).to_not be_nil
    end

    it "creates a valid user" do
      expect(subject.valid?).to be_true
    end

    it "sends an email to that users email" do
      trainer.invite_client("someclient@example.com")
      mail = ActionMailer::Base.deliveries.last
      expect(mail['to'].to_s).to eql("someclient@example.com")
    end

    it "sets who that user was invited by" do
      expect(subject.invited_by_id).to eql(trainer.id)
    end
  end
end
