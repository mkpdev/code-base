# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(128)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  first_name             :string(255)
#  last_name              :string(255)
#  username               :string(255)
#  avatar_url             :string(255)
#  admin                  :boolean
#  age                    :integer
#  sex                    :string(255)
#  location               :string(255)
#  height                 :string(255)
#  invited_by_id          :integer
#  temporary_password     :string(255)
#  time_zone              :string(255)
#

class User < ActiveRecord::Base
  GENDER_OPTIONS = [['male', 'Male'], ['female', 'Female']]
  has_many :exercises
  has_many :comments
  has_many :workouts
  has_many :log_entries, dependent: :destroy
  has_many :appointments
  has_many :trainer_appointments, :class_name => "Appointment", :foreign_key => "trainer_id"
  has_many :scheduled_workouts, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_one :subscription
  has_one :plan, through: :subscription
  has_and_belongs_to_many :trainers,
        :foreign_key => 'client_id',
        :association_foreign_key => 'trainer_id',
        :class_name => 'User',
        :join_table => 'trainers_clients'
  has_and_belongs_to_many :clients,
        :foreign_key => 'trainer_id',
        :association_foreign_key => 'client_id',
        :class_name => 'User',
        :join_table => 'trainers_clients'

  validates :first_name, presence: true
  validates_inclusion_of :time_zone, in: ActiveSupport::TimeZone.zones_map(&:name)

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :temporary_password, :remember_me, 
    :first_name, :last_name, :avatar_url, :age, :sex, :location, :height, :weight, :target_weight, 
    :invited_by_id, :time_zone

  class NotEnoughClientSlots < Exception; end;
  class NotATrainer < Exception; end;

  def chart_body_weight_data(start = 1.month.ago)
    weight_days = self.weight_by_day(start)
    weight_days.map do |weight|
      {
        created_at: weight.created_at,
        weight: weight.weight,
        target_weight: self.target_weight
      }
    end
  end

  def weight_by_day(start = 1.month.ago)
    goal = self.goals.where(name: 'weight').first
    goal.log_entries.where(created_at: start.beginning_of_day..Time.zone.now)
  end

  def trainer_exercises
    @trainer_exercises = []
    self.trainers.each do |trainer|
      @trainer_exercises << trainer.exercises.all
    end
    @trainer_exercises
  end

  def self.trainers
    where(:trainer => true)
  end

  def exercises_attempted(count = 50)
    self.log_entries.exercises.limit(count).collect {|log_entry| log_entry.loggable}.uniq
  end

  def add_trainer(user)
    raise NotATrainer, "You must be a trainer to add a client" if !user.trainer?
    raise "Already a trainer" if self.trainers.include?(user)
    raise NotEnoughClientSlots, "Cannot add client. Upgrade your plan for more slots." if user.clients.size >= user.plan.client_slots
    self.trainers << user if user.trainer?
  rescue NotATrainer => e
    logger.error "Not a trainer. #{e.message}"
    errors.add :base, "#{e.message}"
    false
  rescue NotEnoughClientSlots => e
    logger.error "Need more slots for user. #{e.message}"
    errors.add :base, "#{e.message}"
    false
  end

  def is_a_trainer_of?(trainee)
    self.clients.include?(trainee)
  end

  def is_a_client_of?(trainer)
    self.trainers.include?(trainer)
  end

  def has_a_trainer?
    self.trainers.present?
  end

  def next_appointment_for(trainer)
    self.appointments.find(:all, :conditions => {:trainer_id => trainer.id}, :order => "start_at DESC", :limit => 1).first
  end

  def trainer?
    return false if self.subscription.nil?
    self.subscription.active?
  end

  def client_slots_consumed_percentage
    (clients.size.to_f / plan.client_slots.to_f) * 100
  end

  def subscription_plan?
    return false if self.subscription.plan_id.nil?
    self.subscription.plan_id?
  end

  def target_weight
    goal = self.goals.where(name: 'weight').first
    return 'Not Set' if goal.blank?
    goal.target_value
  end

  def target_weight=(value)
    goal = self.goals.find_or_create_by_name("weight")
    goal.target_value = value
    goal.save
  end

  def weight
    goal = self.goals.where(name: 'weight').first
    return 'Not Set' if goal.blank? || goal.recent_recording.blank?
    goal.recent_recording.weight
  end

  def weight=(value)
    goal = self.goals.find_or_create_by_name("weight")
    goal.record_recent_value(weight: value)
  end

  def invite_client(email)
    password = Devise.friendly_token.first(8)
    user = User.create!(first_name: "Unknown", temporary_password: password, password: password, password_confirmation: password, email: email, invited_by_id: self.id, time_zone: "Pacific Time (US & Canada)")
    ClientMailer.deliver_credentials(self, user).deliver!
    user
  end

  def remove_client(client)
    destroyed = self.clients.destroy(client)
    appointments = self.trainer_appointments.for_user(client)
    appointments.each {|each| each.destroy}
    destroyed
  end

  def todays_all_appointments
    self.trainer_appointments.where("DATE(start_at) = ?", Date.today)
  end

  def reminder_email_for_trainer
    if self.trainer? && self.todays_all_appointments.present?
      ClientMailer.today_appointment_for_trainer(self, self.todays_all_appointments).deliver
      puts "==========sent today reminder email to trainer============"
    end
  end

end
