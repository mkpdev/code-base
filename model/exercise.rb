# == Schema Information
#
# Table name: exercises
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  description          :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  picture_url          :string(255)
#  exercise_category_id :integer
#  summary              :string(255)
#  user_id              :integer
#

class Exercise < ActiveRecord::Base

  EXERCISE_CATEGORIES = %w(weightlifting cardio crossfit)

  has_many :exercise_workouts
  has_many :workouts, :through => :exercise_workouts
  #has_many :log_entries, :through => :exercise_workouts
  has_many :log_entries, :as => :loggable, :dependent => :destroy
  has_and_belongs_to_many :muscle_groups
  belongs_to :exercise_category, inverse_of: :exercises
  belongs_to :user

  attr_accessible :muscle_group_ids
  attr_accessible :exercise_category_id
  attr_accessible :exercise_category


  accepts_nested_attributes_for :log_entries, :allow_destroy => true

  validates_presence_of :name
  validates_presence_of :exercise_category
  validates :name, :uniqueness => {:case_sensitive => false}

  attr_accessible :name, :description, :log_entries_attributes, :picture_url, :workout_log_entries_attributes

  before_save :downcase

  def self.all_public_exercises
    not_the_placeholder_exercise.not_custom.order("name").all
  end

  def self.not_the_placeholder_exercise
    where("exercises.name != ?", "placeholder exercise")
  end

  def self.not_custom
    where(user_id: nil)
  end

  def custom?
    self.user_id.present?
  end

  def downcase
    self.name.downcase!
  end

  def weightlifting?
    return false if self.exercise_category.nil?
    self.exercise_category.name.downcase == 'weightlifting'
  end

  def crossfit?
    return false if self.exercise_category.nil?
    self.exercise_category.name.downcase == 'crossfit'
  end

  def cardio?
    return false if self.exercise_category.nil?
    self.exercise_category.name.downcase == 'cardio'
  end

  def user_chart_data_weight(user)
    self.log_entries.order("created_at ASC").where(:user_id => user.id).collect do |log_entry|
      [log_entry.created_at.to_s(:day_eth), log_entry.weight.to_i]
    end
  end

  def user_chart_data_reps_and_weight(user)
    self.log_entries.order("created_at ASC").where(:user_id => user.id).collect do |log_entry|
      [log_entry.created_at.to_s(:day_eth), log_entry.weight.to_i, log_entry.reps.to_i]
    end
  end

  def total_weight_lifted_for(date)
    self.log_entries.for_date(date).sum(:weight)
  end

  def user_total_weight_lifted_for_each_day(user, start_date = 99.years.ago, end_date = Time.zone.now.end_of_day)
    entries = self.log_entries.for_user(user).for_period(start_date, end_date).collect  do |log_entry|
      [log_entry.created_at.to_s(:day_eth), self.total_weight_lifted_for(log_entry.created_at)]
    end
    entries.uniq
  end

  def total_reps_lifted_for(date)
    self.log_entries.for_date(date).sum(:reps)
  end

  def user_total_reps_lifted_for_each_day(user, start_date = 99.years.ago, end_date = Time.zone.now.end_of_day)
    entries = self.log_entries.for_user(user).for_period(start_date, end_date).collect  do |log_entry|
      [log_entry.created_at.to_s(:day_eth), self.total_reps_lifted_for(log_entry.created_at)]
    end
    entries.uniq
  end

  def maximum_weight_lifted_for(date)
    self.log_entries.for_date(date).maximum(:weight)
  end

  def user_maximum_weight_lifted_for_each_day(user, start_date = 99.years.ago, end_date = Time.zone.now.end_of_day)
    entries = self.log_entries.for_user(user).for_period(start_date, end_date).collect  do |log_entry|
      [log_entry.created_at.to_s(:day_eth), self.maximum_weight_lifted_for(log_entry.created_at)]
    end
    entries.uniq
  end

  def self.placeholder_url
    Exercise.find_or_create_by_name("placeholder exercise").picture_url
  end

  def last_log_entry(user, placeholder = false)
    self.log_entries.for_user(user).order("created_at DESC").where(placeholder: placeholder).limit(1).last
  end

  def last_log_date(user)
    self.last_log_entry(user).created_at.beginning_of_day
  end

  def last_placeholder_log_date(user)
    last_log_entry = self.last_log_entry(user, true)
    if last_log_entry.blank?
      return nil
    else
      self.last_log_entry(user, true).created_at.beginning_of_day
    end
  end

  def placeholder_log_entries(user)
    self.log_entries.placeholders.for_user(user).for_date(last_placeholder_log_date(user))
  end

  def placeholder_log_entries!(user)
    if self.placeholder_log_entries(user).blank?
      self.create_placeholder_log_entries(user)
      self.placeholder_log_entries(user)
    else
      self.placeholder_log_entries(user)
    end
  end

  def create_placeholder_log_entries(user)
    last_log_date = self.last_log_date(user)
    last_log_entries = self.log_entries.for_user(user).for_date(last_log_date).order("id ASC")

    last_log_entries.each do |log_entry|
      self.log_entries.create(placeholder: true, user: user, placeholder_weight: log_entry.weight, placeholder_reps: log_entry.reps, placeholder_duration: log_entry.duration, placeholder_distance: log_entry.distance)
    end
  end

  def chart_weight_data(user, start = 1.month.ago)
    weight_days = self.weight_by_day(start).where(user_id: user.id)
    weight_days.map do |weight|
      {
        created_at: weight.created_at,
        weight: weight.weight,
      }
    end
  end

  def weight_by_day(start = 1.month.ago)
    self.log_entries.where(created_at: start.beginning_of_day..Time.zone.now)
  end


  rails_admin do
    configure :muscle_groups do
      inverse_of :exercises
    end
    configure :log_entries do
      hide
    end
    configure :workouts do
      hide
    end
    configure :exercise_workouts do
      hide
    end
    list do
      field :picture_url do
        formatted_value do
          bindings[:view].render partial: 'filepicker_image', :locals => {:picture_url => bindings[:object].picture_url}
        end
      end
      field :name
    end
    edit do
      field :picture_url do
        partial "filepicker_field"
      end
      include_all_fields
    end
  end
end
