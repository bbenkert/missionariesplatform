module Admin::UsersHelper
  def user_status_badge(user)
    case user.status
    when 'active'
      content_tag :span, 'Active', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800'
    when 'pending'
      content_tag :span, 'Pending', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800'
    when 'suspended'
      content_tag :span, 'Suspended', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800'
    when 'inactive'
      content_tag :span, 'Inactive', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
    else
      content_tag :span, user.status.humanize, class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
    end
  end

  def user_role_badge(user)
    case user.role
    when 'admin'
      content_tag :span, 'Admin', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800'
    when 'organization_admin'
      content_tag :span, 'Org Admin', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800'
    when 'missionary'
      content_tag :span, 'Missionary', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800'
    when 'supporter'
      content_tag :span, 'Supporter', class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800'
    else
      content_tag :span, user.role.humanize, class: 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
    end
  end

  def user_email_status_badge(user)
    if user.email_verified?
      content_tag :span, class: 'inline-flex items-center' do
        content_tag(:i, '', class: 'fas fa-check-circle text-green-500 text-sm mr-1') +
        content_tag(:span, 'Verified', class: 'text-green-700 text-sm')
      end
    else
      content_tag :span, class: 'inline-flex items-center' do
        content_tag(:i, '', class: 'fas fa-exclamation-triangle text-yellow-500 text-sm mr-1') +
        content_tag(:span, 'Unverified', class: 'text-yellow-700 text-sm')
      end
    end
  end

  def last_sign_in_text(user)
    if user.last_sign_in_at
      "#{time_ago_in_words(user.last_sign_in_at)} ago"
    else
      "Never"
    end
  end

  def user_activity_status(user)
    if user.last_sign_in_at && user.last_sign_in_at > 7.days.ago
      { text: "Active", class: "text-green-600", icon: "fas fa-circle" }
    elsif user.last_sign_in_at && user.last_sign_in_at > 30.days.ago
      { text: "Recent", class: "text-yellow-600", icon: "fas fa-circle" }
    elsif user.last_sign_in_at
      { text: "Inactive", class: "text-red-600", icon: "fas fa-circle" }
    else
      { text: "Never Active", class: "text-gray-600", icon: "fas fa-circle" }
    end
  end

  def user_stats_card(title, value, icon, color = "indigo")
    content_tag :div, class: "bg-white/70 backdrop-blur-sm rounded-2xl shadow-xl border border-white/20 p-6" do
      content_tag(:div, class: "flex items-center") do
        content_tag(:div, class: "w-12 h-12 bg-gradient-to-r from-#{color}-500 to-#{color}-600 rounded-xl flex items-center justify-center mr-4") do
          content_tag(:i, '', class: "#{icon} text-white text-xl")
        end +
        content_tag(:div) do
          content_tag(:p, title, class: "text-sm font-medium text-gray-600") +
          content_tag(:p, value, class: "text-2xl font-bold text-gray-900")
        end
      end
    end
  end

  def format_user_activity_item(item)
    case item[:type]
    when 'sign_in'
      {
        icon: 'fas fa-sign-in-alt',
        color: 'green',
        title: 'Signed In',
        description: "User signed in from #{item[:ip] || 'unknown IP'}"
      }
    when 'profile_update'
      {
        icon: 'fas fa-user-edit',
        color: 'blue',
        title: 'Profile Updated',
        description: 'User updated their profile information'
      }
    when 'prayer_request'
      {
        icon: 'fas fa-pray',
        color: 'purple',
        title: 'Prayer Request Created',
        description: 'Created a new prayer request'
      }
    when 'message_sent'
      {
        icon: 'fas fa-paper-plane',
        color: 'indigo',
        title: 'Message Sent',
        description: 'Sent a message to another user'
      }
    else
      {
        icon: 'fas fa-info-circle',
        color: 'gray',
        title: 'Activity',
        description: item[:description] || 'User activity'
      }
    end
  end

  def filter_options
    {
      roles: [
        ['All Roles', ''],
        ['Supporters', 'supporter'],
        ['Missionaries', 'missionary'],
        ['Organization Admins', 'organization_admin'],
        ['Admins', 'admin']
      ],
      statuses: [
        ['All Statuses', ''],
        ['Active', 'active'],
        ['Pending', 'pending'],
        ['Suspended', 'suspended'],
        ['Inactive', 'inactive']
      ],
      email_verified: [
        ['All Users', ''],
        ['Verified Email', 'true'],
        ['Unverified Email', 'false']
      ]
    }
  end

  def bulk_action_options
    [
      ['Select Action', ''],
      ['Approve Selected Missionaries', 'approve_missionaries'],
      ['Suspend Selected Users', 'suspend'],
      ['Activate Selected Users', 'activate'],
      ['Delete Selected Users', 'delete']
    ]
  end
end
