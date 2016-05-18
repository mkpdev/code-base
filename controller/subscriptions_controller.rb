class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!

  def change_plan
    @subscription = current_user.subscription || current_user.build_subscription
    plan = Plan.find params[:plan_id]

    if @subscription.change_plan_to(plan)
      flash[:user_converted] = "You are now a trainer. How's it feel?"
      redirect_to plans_path
    else
      redirect_to plans_path, notice: "Oh noes, we're unable to change the plans. #{@subscription.errors.full_messages.to_sentence}"
    end
  end

  def create
    @subscription = current_user.build_subscription
    @subscription.user = current_user
    @subscription.create_stripe_customer

    if @subscription.update_card(params[:stripeToken]) && @subscription.save!
      redirect_to plans_path, notice: "You have an active card on the account now. Looking good!"
    else
      # Delete stripe customer if it fails during creation, otherwise will create duplicates.
      cu = Stripe::Customer.retrieve(@subscription.stripe_customer_token)
      cu.delete
      redirect_to plans_path, notice: "#{@subscription.errors.full_messages.to_sentence}"
    end
  end

  def update
    @subscription = current_user.subscription
    if @subscription.update_card(params[:stripeToken]) && @subscription.save!
      redirect_to plans_path, notice: 'Has that new card been working out? It looks great!'
    else
      redirect_to plans_path, notice: "#{@subscription.errors.full_messages.to_sentence}"
    end
  end

  def cancel
    @subscription = current_user.subscription

    if @subscription.cancel_subscription
      redirect_to plans_path, notice: "Account cancelled. :("
    else
      redirect_to plans_path, error: "Something went wrong canceling your subscription."
    end
  end
end
