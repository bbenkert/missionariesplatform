require 'rails_helper'

RSpec.describe 'Database Schema' do
  describe 'Users table' do
    it 'has all required columns' do
      columns = User.column_names
      expect(columns).to include('id', 'email', 'name', 'password_digest', 'role', 'status', 'is_active')
      expect(columns).to include('password_reset_token', 'password_reset_sent_at', 'last_sign_in_at', 'last_sign_in_ip')
      expect(columns).to include('created_at', 'updated_at')
    end

    it 'has proper column types' do
      expect(User.columns_hash['email'].type).to eq(:string)
      expect(User.columns_hash['name'].type).to eq(:string)
      expect(User.columns_hash['password_digest'].type).to eq(:string)
      expect(User.columns_hash['role'].type).to eq(:integer)
      expect(User.columns_hash['status'].type).to eq(:integer)
      expect(User.columns_hash['is_active'].type).to eq(:boolean)
    end

    it 'has proper indexes' do
      indexes = ActiveRecord::Base.connection.indexes('users')
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_users_on_email')
      expect(index_names).to include('index_users_on_password_reset_token')
      expect(index_names).to include('index_users_on_role')
      expect(index_names).to include('index_users_on_status')
    end

    it 'has unique constraints' do
      email_index = ActiveRecord::Base.connection.indexes('users').find { |i| i.name == 'index_users_on_email' }
      reset_token_index = ActiveRecord::Base.connection.indexes('users').find { |i| i.name == 'index_users_on_password_reset_token' }

      expect(email_index.unique).to be_truthy
      expect(reset_token_index.unique).to be_truthy
    end
  end

  describe 'MissionaryProfiles table' do
    it 'has all required columns' do
      columns = MissionaryProfile.column_names
      expect(columns).to include('id', 'user_id', 'bio', 'ministry_focus', 'organization', 'country', 'city')
      expect(columns).to include('prayer_requests', 'giving_links', 'website_url', 'social_media_links')
      expect(columns).to include('started_ministry_at', 'ministry_description', 'accepting_messages')
      expect(columns).to include('created_at', 'updated_at')
    end

    it 'has proper column types' do
      expect(MissionaryProfile.columns_hash['user_id'].type).to eq(:integer)
      expect(MissionaryProfile.columns_hash['bio'].type).to eq(:text)
      expect(MissionaryProfile.columns_hash['ministry_focus'].type).to eq(:string)
      expect(MissionaryProfile.columns_hash['accepting_messages'].type).to eq(:boolean)
    end

    it 'has proper indexes' do
      indexes = ActiveRecord::Base.connection.indexes('missionary_profiles')
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_missionary_profiles_on_user_id')
      expect(index_names).to include('index_missionary_profiles_on_country')
      expect(index_names).to include('index_missionary_profiles_on_ministry_focus')
      expect(index_names).to include('index_missionary_profiles_on_organization')
    end

    it 'has unique constraint on user_id' do
      user_index = ActiveRecord::Base.connection.indexes('missionary_profiles').find { |i| i.name == 'index_missionary_profiles_on_user_id' }
      expect(user_index.unique).to be_truthy
    end
  end

  describe 'MissionaryUpdates table' do
    it 'has all required columns' do
      columns = MissionaryUpdate.column_names
      expect(columns).to include('id', 'user_id', 'title', 'content', 'update_type', 'status')
      expect(columns).to include('is_urgent', 'tags', 'published_at', 'created_at', 'updated_at')
    end

    it 'has proper column types' do
      expect(MissionaryUpdate.columns_hash['user_id'].type).to eq(:integer)
      expect(MissionaryUpdate.columns_hash['title'].type).to eq(:string)
      expect(MissionaryUpdate.columns_hash['content'].type).to eq(:text)
      expect(MissionaryUpdate.columns_hash['update_type'].type).to eq(:integer)
      expect(MissionaryUpdate.columns_hash['status'].type).to eq(:integer)
      expect(MissionaryUpdate.columns_hash['is_urgent'].type).to eq(:boolean)
    end

    it 'has proper indexes' do
      indexes = ActiveRecord::Base.connection.indexes('missionary_updates')
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_missionary_updates_on_user_id')
      expect(index_names).to include('index_missionary_updates_on_status')
      expect(index_names).to include('index_missionary_updates_on_published_at')
      expect(index_names).to include('index_missionary_updates_on_update_type')
      expect(index_names).to include('index_missionary_updates_on_is_urgent')
      expect(index_names).to include('index_missionary_updates_on_tags')
    end
  end

  describe 'SupporterFollowings table' do
    it 'has all required columns' do
      columns = SupporterFollowing.column_names
      expect(columns).to include('id', 'supporter_id', 'missionary_id', 'is_active', 'email_notifications')
      expect(columns).to include('created_at', 'updated_at')
    end

    it 'has proper column types' do
      expect(SupporterFollowing.columns_hash['supporter_id'].type).to eq(:integer)
      expect(SupporterFollowing.columns_hash['missionary_id'].type).to eq(:integer)
      expect(SupporterFollowing.columns_hash['is_active'].type).to eq(:boolean)
      expect(SupporterFollowing.columns_hash['email_notifications'].type).to eq(:boolean)
    end

    it 'has proper indexes' do
      indexes = ActiveRecord::Base.connection.indexes('supporter_followings')
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_supporter_followings_on_supporter_id')
      expect(index_names).to include('index_supporter_followings_on_missionary_id')
      expect(index_names).to include('index_supporter_followings_on_is_active')
      expect(index_names).to include('index_supporter_followings_unique')
    end

    it 'has unique constraint on supporter_id and missionary_id' do
      unique_index = ActiveRecord::Base.connection.indexes('supporter_followings').find { |i| i.name == 'index_supporter_followings_unique' }
      expect(unique_index.unique).to be_truthy
      expect(unique_index.columns).to include('supporter_id', 'missionary_id')
    end
  end

  describe 'Conversations table' do
    it 'has all required columns' do
      columns = Conversation.column_names
      expect(columns).to include('id', 'sender_id', 'recipient_id', 'is_blocked', 'blocked_at')
      expect(columns).to include('created_at', 'updated_at')
    end

    it 'has proper column types' do
      expect(Conversation.columns_hash['sender_id'].type).to eq(:integer)
      expect(Conversation.columns_hash['recipient_id'].type).to eq(:integer)
      expect(Conversation.columns_hash['is_blocked'].type).to eq(:boolean)
    end

    it 'has proper indexes' do
      indexes = ActiveRecord::Base.connection.indexes('conversations')
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_conversations_on_sender_id')
      expect(index_names).to include('index_conversations_on_recipient_id')
      expect(index_names).to include('index_conversations_on_is_blocked')
      expect(index_names).to include('index_conversations_on_updated_at')
      expect(index_names).to include('index_conversations_on_sender_id_and_recipient_id')
    end

    it 'has unique constraint on sender_id and recipient_id' do
      unique_index = ActiveRecord::Base.connection.indexes('conversations').find { |i| i.name == 'index_conversations_on_sender_id_and_recipient_id' }
      expect(unique_index.unique).to be_truthy
    end
  end

  describe 'Messages table' do
    it 'has all required columns' do
      columns = Message.column_names
      expect(columns).to include('id', 'conversation_id', 'sender_id', 'content', 'read_at')
      expect(columns).to include('created_at', 'updated_at')
    end

    it 'has proper column types' do
      expect(Message.columns_hash['conversation_id'].type).to eq(:integer)
      expect(Message.columns_hash['sender_id'].type).to eq(:integer)
      expect(Message.columns_hash['content'].type).to eq(:text)
    end

    it 'has proper indexes' do
      indexes = ActiveRecord::Base.connection.indexes('messages')
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_messages_on_conversation_id')
      expect(index_names).to include('index_messages_on_sender_id')
      expect(index_names).to include('index_messages_on_created_at')
      expect(index_names).to include('index_messages_on_read_at')
    end
  end

  describe 'ActiveStorage tables' do
    it 'has active_storage_blobs table' do
      expect(ActiveRecord::Base.connection.table_exists?('active_storage_blobs')).to be_truthy
    end

    it 'has active_storage_attachments table' do
      expect(ActiveRecord::Base.connection.table_exists?('active_storage_attachments')).to be_truthy
    end

    it 'has active_storage_variant_records table' do
      expect(ActiveRecord::Base.connection.table_exists?('active_storage_variant_records')).to be_truthy
    end
  end

  describe 'ActionText tables' do
    it 'has action_text_rich_texts table' do
      expect(ActiveRecord::Base.connection.table_exists?('action_text_rich_texts')).to be_truthy
    end
  end

  describe 'Foreign key constraints' do
    it 'has foreign key from missionary_profiles to users' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys('missionary_profiles')
      fk = foreign_keys.find { |fk| fk.from_table == 'missionary_profiles' && fk.to_table == 'users' }
      expect(fk).to be_present
      expect(fk.column).to eq('user_id')
    end

    it 'has foreign key from missionary_updates to users' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys('missionary_updates')
      fk = foreign_keys.find { |fk| fk.from_table == 'missionary_updates' && fk.to_table == 'users' }
      expect(fk).to be_present
      expect(fk.column).to eq('user_id')
    end

    it 'has foreign keys from supporter_followings to users' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys('supporter_followings')
      supporter_fk = foreign_keys.find { |fk| fk.column == 'supporter_id' }
      missionary_fk = foreign_keys.find { |fk| fk.column == 'missionary_id' }

      expect(supporter_fk).to be_present
      expect(missionary_fk).to be_present
    end

    it 'has foreign keys from conversations to users' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys('conversations')
      sender_fk = foreign_keys.find { |fk| fk.column == 'sender_id' }
      recipient_fk = foreign_keys.find { |fk| fk.column == 'recipient_id' }

      expect(sender_fk).to be_present
      expect(recipient_fk).to be_present
    end

    it 'has foreign keys from messages' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys('messages')
      conversation_fk = foreign_keys.find { |fk| fk.column == 'conversation_id' }
      sender_fk = foreign_keys.find { |fk| fk.column == 'sender_id' }

      expect(conversation_fk).to be_present
      expect(sender_fk).to be_present
    end
  end
end
