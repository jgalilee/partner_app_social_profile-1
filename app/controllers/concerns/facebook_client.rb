module FacebookClient
  extend ActiveSupport::Concern

  protected

  def facebook_load_profile
    OpenStruct.new(facebook_token.get("/me?fields=#{facebook_profile_fields}").parsed)
  end

  def facebook_profile_fields
    [
      :email,
      :name,
      :first_name,
      :last_name,
      :gender,
      :birthday,
      :picture
    ].join(',')
  end

  def facebook_authorize_uri(app_id, redirect_uri)
    facebook_client_settings[:authorize_url] % [app_id, redirect_uri]
  end

  def facebook_default_client
    @default_client ||= facebook_client(facebook_client_settings)
  end

  def facebook_client(settings)
    app_id = settings[:app_id]
    secret_key = settings[:secret_key]
    site_url = settings[:site_url]
    token_url = settings[:token_url]
    @client ||= OAuth2::Client.new(app_id, secret_key, {
      site: site_url,
      token_url: token_url,
      scope: 'user_about_me'
    })
  end

  def facebook_client_settings
    if !defined?(@settings)
      file = ERB.new(File.read("#{Rails.root}/config/social/facebook.yml.erb"))
      settings = YAML.load(file.result)
      @settings = settings[Rails.env].symbolize_keys
    end
    @settings
  end

  def facebook_token
    @token ||= OAuth2::AccessToken.from_hash(facebook_default_client, facebook_token_hash)
  end

  def facebook_token_hash
    if session.has_key? "profile"
      if session["profile"].has_key? "token"
        @token_hash ||= session["profile"]["token"].dup
      end
    end
    @token_hash
  end

  def facebook_save_token(token)
    session[:profile] = { type: :facebook, token: token.to_hash }
  end

  def facebook_has_session?
    facebook_token_hash.present? && !facebook_token.expired?
  end

  def facebook_token_present?
    unless facebook_has_session?
      flash[:notice] = "Your session has expired."

      redirect_to root_url
    end
  end
end
