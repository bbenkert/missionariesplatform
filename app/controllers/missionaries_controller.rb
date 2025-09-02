class MissionariesController < ApplicationController
  before_action :require_authentication, except: [:index, :show]

  def index
    @missionaries = User.approved_missionaries
                       .includes(:organization, 
                                 missionary_profile: :organization, 
                                 avatar_attachment: :blob)
                       .joins(:missionary_profile)

    # Filtering
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { country: params[:country] }) if params[:country].present?
    # Updated organization filtering to use organization_id
    @missionaries = @missionaries.joins(:organization)
                                .where(organizations: { name: params[:organization] }) if params[:organization].present?
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { ministry_focus: params[:ministry_focus] }) if params[:ministry_focus].present?

    # Search with FTS and Trigram
    if params[:search].present?
      search_term = params[:search]
      # Basic FTS query (using simple dictionary for broader matches)
      fts_query = "to_tsvector('simple', users.name || ' ' || missionary_profiles.bio || ' ' || missionary_profiles.ministry_focus) @@ plainto_tsquery('simple', :search)"

      # Trigram similarity search
      trigram_query = <<-SQL
        users.name % :search OR
        missionary_profiles.bio % :search OR
        missionary_profiles.ministry_focus % :search OR
        missionary_profiles.slug % :search OR
        organizations.name % :search
      SQL

      # Combine FTS and Trigram, prioritizing FTS matches
      @missionaries = @missionaries.left_joins(:organization) # Ensure organization is joined for search
                                  .where(fts_query + ' OR ' + trigram_query, search: search_term)
                                  .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array([
                                    "ts_rank(to_tsvector('simple', users.name || ' ' || missionary_profiles.bio || ' ' || missionary_profiles.ministry_focus), plainto_tsquery('simple', ?)) DESC, \
                                    similarity(users.name, ?) DESC, \
                                    similarity(missionary_profiles.bio, ?) DESC",
                                    search_term, search_term, search_term
                                  ])))
    end

    @pagy, @missionaries = pagy(@missionaries, items: 12)

    # For filters
    @countries = MissionaryProfile.joins(:user)
                                 .where(users: { status: 'approved' })
                                 .distinct
                                 .pluck(:country)
                                 .compact
                                 .sort
    # Updated organizations filter to pluck from Organization model
    @organizations = Organization.joins(missionary_profiles: :user)
                                 .where(users: { status: 'approved' })
                                 .distinct
                                 .pluck(:name)
                                 .compact
                                 .sort
  end

  def show
    @missionary = User.approved_missionaries
                     .includes(missionary_profile: :organization, 
                              missionary_updates: [], 
                              organization: [])
                     .find(params[:id])
    @updates = @missionary.missionary_updates.published.visible_to(current_user).recent.limit(10)
    @prayer_requests = @missionary.missionary_profile.prayer_requests.published.visible_to(current_user).recent.limit(5)
    @can_message = current_user&.can_message?(@missionary)
  rescue ActiveRecord::RecordNotFound
    redirect_to missionaries_path, alert: "Missionary not found or not approved"
  end
end
