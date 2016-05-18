# == Schema Information
#
# Table name: subscriptions
#
#  id                    :integer          not null, primary key
#  plan_id               :integer
#  user_id               :integer
#  active                :boolean
#  last_4_digits         :string(255)
#  stripe_customer_token :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Subscription < ActiveRecord::Base
  belongs_to :plan
  belongs_to :user

  #validates :plan_id, presence: true, on: :create
  validates :user_id, presence: true, uniqueness: true
  validates :stripe_customer_token, presence: true

  attr_accessible :stripe_card_token, :stripe_customer_token

  attr_accessor :stripe_card_token

  class LessClientSlots < Exception; end;

  def active_card_on_file?
    self.last_4_digits.present?
  end

  def change_plan_to(plan)
    if self.stripe_customer_token.blank?
      self.create_stripe_customer
    end
    update_plan(plan, user)
  rescue Stripe::InvalidRequestError => e
    logger.error "[STRIPE] #{e}"
    errors.add :base, "Unable to change plan"
    false
  end

  def cancel_subscription
    self.track_cancelled_subscription
    self.active = false
    self.plan = nil
    unless stripe_customer_token.nil?
      customer = Stripe::Customer::retrieve(stripe_customer_token)
      customer.cancel_subscription
    end
    save!
  rescue Stripe::StripeError => e
    logger.error "Stripe Error: " + e.message
    errors.add :base, "Unable to cancel your subscription. #{e.message}."
    false
  end

  def expire!
    self.track_expired_subscription
    SubscriptionMailer.expire_email(self).deliver
    self.active = false
    self.plan = nil
    save!
  end

  def create_stripe_customer
    customer = Stripe::Customer.create description: user.id, email: user.email
    self.stripe_customer_token = customer.id
  rescue Stripe::InvalidRequestError => e
    logger.error "[STRIPE] #{ e }"
    errors.add :base, "Unable to create a customer!"
    false 
  end

  def update_card(card)
    customer            = stripe_customer
    customer.card       = card
    customer            = customer.save
    default_card        = customer.cards.data.first
    self.last_4_digits  = default_card.last4
  rescue Stripe::CardError => e
    logger.error "[STRIPE] #{e}"
    errors.add :base, "#{e}"
    false
  end

  def track_changed_plan
    Analytics.track(
      user_id:    self.user_id,
      event:      'Changed plan',
      properties: {
        plan:     self.plan.name,
        revenue:  self.plan.price
      }
    )
  end

  def track_cancelled_subscription
    Analytics.track(
      user_id:    self.user_id,
      event:      'Cancelled Subscription',
      properties: {
        plan:     self.plan.name,
      }
    )
  end

  def track_expired_subscription
    Analytics.track(
      user_id:    self.user_id,
      event:      'Expired Subscription',
      properties: {
        plan:     self.plan.name,
      }
    )
  end

  private

  def stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve stripe_customer_token
  end

  def update_plan(plan, user)
    raise LessClientSlots, "This New plan has #{plan.client_slots} client slots and you have #{user.clients.size} clients in your list. Please delete extra clients first." if user.clients.size > plan.client_slots
    stripe_customer = Stripe::Customer.retrieve(self.stripe_customer_token)
    stripe_customer.update_subscription(plan: plan.slug)
    if self.valid?
      self.active = true
      self.plan = plan
      self.track_changed_plan
      self.save!
    end
  rescue LessClientSlots => e
    logger.error "Need clients to be deleted. #{e.message}"
    errors.add :base, "#{e.message}"
    false
  end
end
