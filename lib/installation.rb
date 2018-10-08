# frozen_string_literal: true

require 'jwt'

class Installation
  attr_reader :id, :token, :token_expires_at

  def initialize(id)
    @id = id
  end

  def current_token
    if token_expired?
      fetch_token
    else
      token
    end
  end

  private

  def token_expired?
    return true if token.nil?

    token_expires_at < Time.now
  end

  def fetch_token
    client = Octokit::Client.new(bearer_token: jwt_assertion)
    response = client.create_app_installation_access_token(id, accept: 'application/vnd.github.machine-man-preview+json')
    @token = response['token']
    @token_expires_at = response['expires_at']
    @token
  end

  def jwt_assertion
    payload = {
      iat: Time.now.to_i,
      exp: Time.now + (60 * 15), # 15 minutes from now
      iss: integration_id.to_i
    }
    key = OpenSSL::PKey::RSA.new(integration_private_key)
    JWT.encode(payload, key, 'RS256')
  end
end
