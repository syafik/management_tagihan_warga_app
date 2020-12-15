# frozen_string_literal: true

module ApplicationHelper
  def errors_for(object)
    if object.errors.any?
      content_tag(:div, class: 'card-body border-danger') do
        concat(content_tag(:div, class: 'card-header bg-danger text-white') do
          concat "#{pluralize(object.errors.count,
                              'error')} prohibited this #{object.class.name.downcase} from being saved:"
        end)
        concat(content_tag(:div, class: 'card-body') do
          concat(content_tag(:ul, class: 'mb-0') do
            object.errors.full_messages.each do |msg|
              concat content_tag(:li, msg)
            end
          end)
        end)
      end
    end
  end

  def date_format(datetime)
    return '-' if datetime.nil?

    datetime.strftime('%b, %d %Y %H:%M:%S')
  end

  def user_answer(answer)
    answer.gsub('-', ' ').titleize
  end

  def bootstrap_class_for(flash_type)
    { success: 'alert-success', error: 'alert-danger', alert: 'alert-danger',
      notice: 'alert-info' }.stringify_keys[flash_type.to_s] || flash_type.to_s
  end

  def flash_messages(_opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)}", role: 'alert') do
               concat content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
               concat message
             end)
    end
    nil
  end
end
