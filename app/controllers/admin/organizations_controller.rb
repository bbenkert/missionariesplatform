class Admin::OrganizationsController < ApplicationController
  before_action :require_admin
  before_action :set_organization, only: [:show, :edit, :update, :destroy]

  def index
    organizations_query = Organization.includes(:missionary_profiles, :users)
                                     .by_name
    @pagy, @organizations = pagy(organizations_query)
  end

  def show
    @missionaries = @organization.missionaries.includes(:missionary_profile)
    @recent_activity = @organization.missionary_profiles
                                   .joins(:missionary_updates)
                                   .merge(MissionaryUpdate.order(created_at: :desc))
                                   .limit(10)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    
    if @organization.save
      redirect_to admin_organization_path(@organization), notice: 'Organization created successfully'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to admin_organization_path(@organization), notice: 'Organization updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @organization.destroy
    redirect_to admin_organizations_path, notice: 'Organization deleted successfully'
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(
      :name, :slug, :description, :website, :contact_email, :phone, 
      :address, :logo_url, :settings
    )
  end
end
