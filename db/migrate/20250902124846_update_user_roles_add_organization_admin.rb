class UpdateUserRolesAddOrganizationAdmin < ActiveRecord::Migration[8.0]
  def change
    # No database changes needed - enum values are stored as integers
    # Added organization_admin: 3 to the User model enum
    # This migration serves as documentation of the model change
  end
end
