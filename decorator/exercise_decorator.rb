class ExerciseDecorator < Draper::Decorator
  delegate_all

  def render_add_text
    if object.cardio?
      "Add Lap"
    else
      "Add Set"
    end
  end

  def format_id
    "exercise_#{object.id}"
  end

  def render_summary
    if object.summary.present?
      h.simple_format object.summary
    else
      h.render "exercises/no_summary"
    end
  end

  def render_description
    if object.description.present?
      h.simple_format object.description
    else
      h.content_tag :p, "There is no description for this exercise yet. Perhaps you can submit one and earn brownie points? :)"
    end
  end

  def path_for_current_user_or_client
    if h.loaded_user == h.current_user
      h.exercise_path(object)
    else 
      h.client_exercise_path(h.loaded_user, object)
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
