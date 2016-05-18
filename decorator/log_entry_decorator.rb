class LogEntryDecorator < Draper::Decorator
  delegate_all

  def display_weight
    object.weight.nil? ? nil : "%g" % object.weight
  end

  def format_id
    "log_entry_#{object.id}"
  end

  def display_rest
    object.rest_after_set.present? ? object.rest_after_set : "not set"
  end

  def display_difficulty
    object.difficulty.present? ? object.difficulty : "not set"
  end

  def display_feed_item
    h.content_tag :span, class: 'log-entry-history-item' do
      if object.weight.present?
        h.concat h.content_tag(:b, " #{object.weight} ", class: 'log-entry-weight')
      end      
      if object.reps.present? && object.weight.present?
        h.concat " x "
      end
      if object.reps.present?
        h.concat h.content_tag(:b, "#{object.reps} ", class: 'log-entry-reps')
        h.concat h.content_tag(:span, "#{object.measurement} ", class: 'label round secondary')
      end
      if object.rest_after_set.present?
        h.concat h.content_tag(:b, " #{object.rest_after_set} minutes ", class: 'log-entry-rest')
        h.concat h.content_tag(:span, "rest", class: 'label round secondary')
      end
      if object.difficulty.present?
        h.concat h.content_tag(:b, " #{object.difficulty}", class: 'log-entry-difficulty')
        h.concat h.content_tag(:span, "difficulty", class: 'label round secondary')
      end
    end
  end
end
