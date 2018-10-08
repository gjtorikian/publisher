require 'octokit'
require 'installation'

def configure_app_client
  Octokit::Client.new(access_token: github_installation_token)
end

def github_installation_token
  github_installation.current_token
end

def github_installation
  @installation ||= Installation.new(ENV['INSTALLATION_ID'])
end

def integration_private_key
  ENV['GITHUB_APP_PEM'].gsub('\n', "\n")
end

def integration_id
  ENV['GITHUB_APP_ID']
end
