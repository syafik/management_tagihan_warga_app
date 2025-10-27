# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Custom Pagy helper for Tailwind CSS styling
  def pagy_tailwind_nav(pagy, pagy_id: nil, **vars)
    p_id = %( id="#{pagy_id}") if pagy_id
    
    html = +%(<div#{p_id} class="bg-white px-4 py-3 flex flex-col sm:flex-row items-center justify-between border-t border-gray-200 sm:px-6 space-y-3 sm:space-y-0">)
    
    # Mobile pagination info
    html << %(<div class="flex-1 flex justify-between sm:hidden">)
    if pagy.prev
      html << %(<a href="#{pagy_url_for(pagy, pagy.prev)}" class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Previous</a>)
    else
      html << %(<span class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-300 bg-white cursor-not-allowed">Previous</span>)
    end
    
    if pagy.next
      html << %(<a href="#{pagy_url_for(pagy, pagy.next)}" class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Next</a>)
    else
      html << %(<span class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-300 bg-white cursor-not-allowed">Next</span>)
    end
    html << %(</div>)
    
    # Desktop pagination
    html << %(<div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">)
    html << %(<div>)
    html << %(<p class="text-sm text-gray-700">)
    html << %(Showing <span class="font-medium">#{pagy.from}</span> to <span class="font-medium">#{pagy.to}</span> of <span class="font-medium">#{pagy.count}</span> results)
    html << %(</p>)
    html << %(</div>)
    
    html << %(<div>)
    html << %(<nav class="isolate inline-flex rounded-md shadow-sm" aria-label="Pagination">)

    # Previous button
    if pagy.prev
      html << %(<a href="#{pagy_url_for(pagy, pagy.prev)}" class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"><span class="sr-only">Previous</span><svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd"/></svg></a>)
    else
      html << %(<span class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-300 ring-1 ring-inset ring-gray-300 cursor-not-allowed"><span class="sr-only">Previous</span><svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd"/></svg></span>)
    end

    # Page numbers
    pagy.series(**vars).each do |item|
      case item
      when Integer
        if item == pagy.page
          html << %(<span aria-current="page" class="relative z-10 inline-flex items-center bg-indigo-600 px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">#{item}</span>)
        else
          html << %(<a href="#{pagy_url_for(pagy, item)}" class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0">#{item}</a>)
        end
      when String
        case item
        when 'gap'
          html << %(<span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0">...</span>)
        end
      end
    end

    # Next button
    if pagy.next
      html << %(<a href="#{pagy_url_for(pagy, pagy.next)}" class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"><span class="sr-only">Next</span><svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/></svg></a>)
    else
      html << %(<span class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-300 ring-1 ring-inset ring-gray-300 cursor-not-allowed"><span class="sr-only">Next</span><svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/></svg></span>)
    end

    html << %(</nav>)
    html << %(</div>)
    html << %(</div>)
    html << %(</div>)
    
    html.html_safe
  end
  def errors_for(object)
    return unless object
    return unless object.errors.any?

    content_tag(:div, class: 'bg-red-50 border border-red-200 rounded-lg p-4 mb-6', role: 'alert') do
      content_tag(:div, class: 'flex items-start') do
        content_tag(:div, class: 'flex-shrink-0') do
          raw '<svg class="h-5 w-5 text-red-400" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/></svg>'
        end +
        content_tag(:div, class: 'ml-3 flex-1') do
          content_tag(:h3, class: 'text-sm font-medium text-red-800') do
            "#{pluralize(object.errors.count, 'kesalahan')} ditemukan:"
          end +
          content_tag(:div, class: 'mt-2 text-sm text-red-700') do
            content_tag(:ul, class: 'list-disc list-inside space-y-1') do
              raw object.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
            end
          end
        end
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

  def tailwind_flash_classes(flash_type)
    case flash_type.to_s
    when 'success', 'notice'
      {
        container: 'bg-green-50 border border-green-200 rounded-md p-4',
        icon: 'text-green-400',
        text: 'text-green-800',
        button: 'text-green-600 hover:text-green-800'
      }
    when 'error', 'alert'
      {
        container: 'bg-red-50 border border-red-200 rounded-md p-4',
        icon: 'text-red-400',
        text: 'text-red-800',
        button: 'text-red-600 hover:text-red-800'
      }
    when 'warning'
      {
        container: 'bg-yellow-50 border border-yellow-200 rounded-md p-4',
        icon: 'text-yellow-400',
        text: 'text-yellow-800',
        button: 'text-yellow-600 hover:text-yellow-800'
      }
    else
      {
        container: 'bg-blue-50 border border-blue-200 rounded-md p-4',
        icon: 'text-blue-400',
        text: 'text-blue-800',
        button: 'text-blue-600 hover:text-blue-800'
      }
    end
  end

  def flash_icon(flash_type)
    case flash_type.to_s
    when 'success', 'notice'
      '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>'.html_safe
    when 'error', 'alert'
      '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z"/>
      </svg>'.html_safe
    when 'warning'
      '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z"/>
      </svg>'.html_safe
    else
      '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>'.html_safe
    end
  end

  def flash_messages(opts = {})
    return if flash.empty?
    
    html = +''
    flash.each do |msg_type, message|
      next if message.blank?
      
      classes = tailwind_flash_classes(msg_type)
      
      html << content_tag(:div, 
        class: "#{classes[:container]} mb-4",
        data: { 
          controller: 'flash-message',
          flash_message_auto_dismiss_value: opts.fetch(:auto_dismiss, true),
          flash_message_timeout_value: opts.fetch(:timeout, 5000)
        }
      ) do
        content_tag(:div, class: 'flex items-start') do
          # Icon
          icon_html = content_tag(:div, class: "flex-shrink-0") do
            content_tag(:div, flash_icon(msg_type), class: classes[:icon])
          end
          
          # Message
          message_html = content_tag(:div, class: 'ml-3 flex-1') do
            content_tag(:p, message, class: "text-sm #{classes[:text]}")
          end
          
          # Close button
          close_html = content_tag(:div, class: 'ml-auto flex-shrink-0') do
            content_tag(:button,
              type: 'button',
              class: "inline-flex #{classes[:button]} focus:outline-none",
              data: { action: 'click->flash-message#dismiss' }
            ) do
              content_tag(:span, '×', class: 'text-xl font-medium')
            end
          end
          
          icon_html + message_html + close_html
        end
      end
    end
    
    html.html_safe
  end

  # Dynamic currency formatting for spreadsheets
  # Options:
  # - currency: :idr (Indonesian Rupiah), :usd (US Dollar), :eur (Euro), etc.
  # - separator: thousands separator (default: '.' for IDR, ',' for others)
  # - decimal_places: number of decimal places (default: 0 for IDR, 2 for others)
  # - prefix: whether to include currency symbol (default: false for spreadsheets)
  def contribution_money_format_for_indonesian_rupiah(amount, options = {})
    return '0' if amount.nil? || amount.zero?
    
    # Default options
    opts = {
      currency: :idr,
      separator: nil,
      decimal_places: nil,
      prefix: false
    }.merge(options)
    
    # Set defaults based on currency
    case opts[:currency]
    when :idr, :rupiah
      opts[:separator] ||= '.'
      opts[:decimal_places] ||= 0
      opts[:symbol] = 'Rp'
    when :usd, :dollar
      opts[:separator] ||= ','
      opts[:decimal_places] ||= 2
      opts[:symbol] = '$'
    when :eur, :euro
      opts[:separator] ||= ','
      opts[:decimal_places] ||= 2
      opts[:symbol] = '€'
    else
      opts[:separator] ||= ','
      opts[:decimal_places] ||= 2
      opts[:symbol] = ''
    end
    
    # Format the number
    if opts[:decimal_places] > 0
      formatted = sprintf("%.#{opts[:decimal_places]}f", amount)
      integer_part, decimal_part = formatted.split('.')
    else
      integer_part = amount.to_i.to_s
      decimal_part = nil
    end
    
    # Add thousands separator
    formatted_integer = integer_part.reverse.gsub(/(\d{3})(?=\d)/, "\\1#{opts[:separator]}").reverse
    
    # Combine parts
    result = formatted_integer
    result += ".#{decimal_part}" if decimal_part
    result = "#{opts[:symbol]} #{result}" if opts[:prefix] && opts[:symbol].present?
    
    result
  end
  
  # Shorter alias for common usage
  def format_currency(amount, currency = :idr, options = {})
    contribution_money_format_for_indonesian_rupiah(amount, options.merge(currency: currency))
  end
end
