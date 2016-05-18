class UserDecorator < Draper::Decorator
  delegate_all

  decorates_association :log_entry

  def total_completeness
    total = 0
    total += 20 if object.avatar_url.present?
    total += 20 if object.weight != "Not Set"
    total += 20 if object.goals.where(:name => 'weight').present?
    total += 20 if object.workouts.present?
    total += 20 if object.log_entries.present?
    return total
  end

  def summary_completeness
    summary = {:avatar => false, :goal => false, :weight => false, :workout => false, :log_entries => false}
    summary[:avatar]      = object.avatar_url.present?
    summary[:weight]      = object.weight != "Not Set"
    summary[:goal]        = object.goals.where(:name => 'weight').present?
    summary[:workout]     = object.workouts.present?
    summary[:log_entries] = object.log_entries.present?

    return summary
  end

  def display_meta
    decorated = object.decorate
    if decorated.display_last_log_date
      "Last workout: #{decorated.display_last_log_date}"
    elsif decorated.sign_in_count >= 1
      "Last seen: #{h.distance_of_time_in_words(decorated.last_sign_in_at, Time.now)} ago"
    else
      decorated.display_pending_status
    end
  end

  def display_last_log_date
    last_date = object.log_entries.last.created_at unless object.log_entries.last.nil?
    if last_date.nil?
      return false
    else
      h.distance_of_time_in_words(last_date, Time.now)
    end
  end

  def display_pending_status
    if object.sign_in_count == 0
      "invite pending..."
    end
  end

  def recent_log_entries_for_exercise(exercise, limit = 3)
    collection = object.log_entries.for_loggable(exercise).order("created_at DESC").limit(limit)
    collection.present? ? h.render(collection) : h.content_tag(:em, "nothing recent... try doing it!")
  end

  def last_log_entry(exercise = nil)
    log_entries = object.log_entries.order("created_at ASC").before_today
    if exercise.present?
      log_entries.for_loggable(exercise).last
    else
      log_entries.last
    end
  end

  def render_last_log_entry(exercise = nil)
    return "Nothing recorded yet." if object.decorate.last_log_entry(exercise).blank?
    object.decorate.last_log_entry(exercise.object).decorate.display_feed_item
  end

  def current_plan
    if object.plan.present?
      object.plan.name
    else
      "none"
    end
  end

  def full_name
    "#{object.first_name} #{object.last_name}"
  end

  def render_recent_clients
    return "You don't have any clients yet." if object.clients.blank?
    h.render(partial: 'clients/client', collection: object.clients.limit(6).decorate, as: :user)
  end

  def render_recent_trainers
    return "You don't have any trainers yet." if object.trainers.blank?
    h.render(partial: 'trainers/trainer', collection: object.trainers.limit(6).decorate, as: :user)
  end

  def render_recent_workouts
    if object.workouts.present?
      h.render(object.workouts.limit(6))
    else
      "You have no workouts yet. That's ok, let's #{h.link_to 'create one now', h.new_workout_path}.".html_safe
    end
  end

  def render_recent_exercises
    h.render(object.exercises_attempted(6))
  end

  def render_upcoming_appointments
    if object.trainer?
      if object.trainer_appointments.upcoming.present?
        h.render(object.trainer_appointments.upcoming.decorate)
      else
        "No upcoming appointments..."
      end
    else
      if object.appointments.upcoming.present?
        h.render(object.appointments.upcoming.decorate)
      else
        "No upcoming appointments..."
      end
    end
  end
  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

end
