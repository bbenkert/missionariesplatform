module ApplicationHelper
  include Pagy::Frontend
  
  def flash_class(type)
    case type.to_s
    when 'notice'
      'bg-green-100 border border-green-400 text-green-700'
    when 'alert'
      'bg-red-100 border border-red-400 text-red-700'
    when 'warning'
      'bg-yellow-100 border border-yellow-400 text-yellow-700'
    else
      'bg-blue-100 border border-blue-400 text-blue-700'
    end
  end

  def user_avatar_tag(user, size: :medium, css_class: "")
    if user.avatar.attached?
      image_tag user.avatar_url(size: size), 
                class: "#{css_class} object-cover", 
                alt: user.name
    else
      content_tag :div, 
                  user.name.first.upcase, 
                  class: "#{css_class} bg-gray-300 flex items-center justify-center text-gray-600 font-semibold"
    end
  end

  def truncate_html(text, length: 150)
    truncate(strip_tags(text), length: length)
  end

  def time_ago_or_date(datetime)
    if datetime > 1.week.ago
      time_ago_in_words(datetime) + " ago"
    else
      datetime.strftime("%B %d, %Y")
    end
  end

  def current_page_title
    case controller_name
    when 'home'
      'Home'
    when 'missionaries'
      action_name == 'index' ? 'Missionaries' : @missionary&.name
    when 'dashboard'
      'Dashboard'
    when 'sessions'
      'Sign In'
    when 'registrations'
      'Sign Up'
    else
      controller_name.humanize
    end
  end

  def meta_title
    base_title = "Missionary Platform"
    page_title = current_page_title
    
    if page_title == 'Home'
      "#{base_title} - Connecting missionaries with supporters worldwide"
    else
      "#{page_title} - #{base_title}"
    end
  end

  def user_role_badge(user)
    case user.role
    when 'missionary'
      content_tag :span, 'Missionary', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-blue-100 text-blue-800 rounded-full'
    when 'supporter'
      content_tag :span, 'Supporter', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-green-100 text-green-800 rounded-full'
    when 'admin'
      content_tag :span, 'Admin', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-purple-100 text-purple-800 rounded-full'
    end
  end

  def status_badge(user)
    case user.status
    when 'pending'
      content_tag :span, 'Pending Approval', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-yellow-100 text-yellow-800 rounded-full'
    when 'approved'
      content_tag :span, 'Approved', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-green-100 text-green-800 rounded-full'
    when 'flagged'
      content_tag :span, 'Flagged for Review', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-red-100 text-red-800 rounded-full'
    when 'suspended'
      content_tag :span, 'Suspended', 
                  class: 'inline-block px-2 py-1 text-xs font-semibold bg-gray-100 text-gray-800 rounded-full'
    end
  end
end
