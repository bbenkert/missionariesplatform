require 'csv'

class Admin::ExportsController < ApplicationController
  before_action :require_admin

  def create
    export_type = params[:export_type] || 'dashboard'
    
    case export_type
    when 'users'
      export_users
    when 'missionaries'
      export_missionaries
    when 'prayer_requests'
      export_prayer_requests
    when 'dashboard'
      export_dashboard
    else
      redirect_to admin_root_path, alert: 'Invalid export type'
    end
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def export_users
    users = User.all.order(created_at: :desc)
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Email', 'Role', 'Status', 'Created At', 'Last Sign In']
      
      users.each do |user|
        csv << [
          user.id,
          user.name,
          user.email,
          user.role,
          user.status,
          user.created_at,
          user.last_sign_in_at
        ]
      end
    end
    
    send_data csv_data, filename: "users_export_#{Date.today}.csv", type: 'text/csv'
  end

  def export_missionaries
    missionaries = User.missionaries.includes(:missionary_profile).order(created_at: :desc)
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Email', 'Organization', 'Country', 'Status', 'Followers', 'Created At']
      
      missionaries.each do |missionary|
        profile = missionary.missionary_profile
        csv << [
          missionary.id,
          missionary.name,
          missionary.email,
          profile&.organization&.name || 'N/A',
          profile&.country || 'N/A',
          missionary.status,
          profile&.followers_count || 0,
          missionary.created_at
        ]
      end
    end
    
    send_data csv_data, filename: "missionaries_export_#{Date.today}.csv", type: 'text/csv'
  end

  def export_prayer_requests
    prayer_requests = PrayerRequest.includes(:missionary_profile).order(created_at: :desc)
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Title', 'Missionary', 'Urgency', 'Status', 'Prayer Count', 'Created At']
      
      prayer_requests.each do |pr|
        csv << [
          pr.id,
          pr.title,
          pr.missionary_profile.user.name,
          pr.urgency,
          pr.status,
          pr.prayer_count,
          pr.created_at
        ]
      end
    end
    
    send_data csv_data, filename: "prayer_requests_export_#{Date.today}.csv", type: 'text/csv'
  end

  def export_dashboard
    data = {
      exported_at: Time.current,
      total_users: User.count,
      total_missionaries: User.where(role: :missionary).count,
      total_supporters: User.where(role: :supporter).count,
      total_prayer_requests: PrayerRequest.count,
      total_organizations: Organization.count,
      total_follows: Follow.count
    }
    
    send_data data.to_json, filename: "dashboard_export_#{Date.today}.json", type: 'application/json'
  end
end
