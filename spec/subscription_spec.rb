require 'spec_helper'

describe Subscription do


  it { should belong_to(:plan) }
  it { should belong_to(:user) }
  it { should validate_presence_of(:user_id) }
  it { should validate_uniqueness_of(:user_id) }
  it { should validate_presence_of(:stripe_customer_token) }

  let(:plan) { Plan.first }
  let(:user) { FactoryGirl.create :user }

  describe "#create_stripe_customer" do

    before do
      @subscription = build(:subscription, user: user)
      @subscription.create_stripe_customer
      @subscription.save
      @stripe_customer = Stripe::Customer.retrieve @subscription.stripe_customer_token
    end


    context "the subscription record" do
      subject { @subscription }

      its(:stripe_customer_token) { should_not be_blank }

    end

    context "stripe customer record" do
      subject { @stripe_customer }

      its(:description) { should == user.id }
      its(:email) { should == user.email }
    end
  end

  describe '#update_card' do
    it "updates card" do
      subscription = FactoryGirl.build :subscription, user: user
      subscription.create_stripe_customer
      subscription.save
      customer = Stripe::Customer.retrieve subscription.stripe_customer_token
      expect(customer.cards.count).to eql(0)
      subscription.update_card('new-token')
      subscription.save
      customer = Stripe::Customer.retrieve subscription.stripe_customer_token
      expect(customer.cards.count).to eql(1)
    end
  end

  describe "#change_plan_to" do
    let(:old_plan) { Plan.find_by_slug "test" }
    let(:new_plan) { Plan.find_by_slug "test-two" }

    it "changes the plan for subscription" do
      subscription = FactoryGirl.build :subscription, user: user
      subscription.create_stripe_customer
      subscription.save
      subscription.update_card "some-token"
      subscription.save
      subscription.change_plan_to(new_plan)

      customer = Stripe::Customer.retrieve subscription.stripe_customer_token
      subscription.plan.should == new_plan
      customer.subscription.plan.id.should == new_plan.slug
    end
  end

  describe "#cancel_subscription" do
    it "cancels the subscription for model and stripe customer" do
      subscription = FactoryGirl.build :subscription, user: user
      subscription.create_stripe_customer
      subscription.save
      subscription.update_card "some-other-token"
      subscription.save
      subscription.change_plan_to(plan)
      subscription.cancel_subscription

      subscription.active.should eql(false)
      subscription.plan.should eql(nil)

      customer = Stripe::Customer.retrieve subscription.stripe_customer_token
      customer.subscription.should eql(nil)
    end
  end

  describe "#expire!" do

    before do
      @subscription = FactoryGirl.build :subscription, user: user
      @subscription.create_stripe_customer
      @subscription.update_card valid_card_data
      @subscription.change_plan_to(plan)
      @subscription.expire!
    end

    subject { @subscription }

    its(:active) { should == false}
    its(:plan) { should == nil }

    it "sends an email to user" do
      SubscriptionMailer.deliveries.last.to.should == [@subscription.user.email]
    end

  end
end
