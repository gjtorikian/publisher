# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

ENV['GITHUB_APP_PEM'] = File.read(File.expand_path('../fixtures/snakeoil.pem.txt', __FILE__))
ENV['INSTALLATION_ID'] = '20'

require 'bundler/setup'
require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require_relative '../lib/app'
require 'resque_spec'
require 'fileutils'

WebMock.disable_net_connect!

module RSpecMixin
  include Rack::Test::Methods
  def app
    Publisher
  end
end

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Run in a random order
  config.order = :random

  config.include RSpecMixin
end

class TestHelper
  include Helpers
end

def fixture_path(fixture)
  File.expand_path "fixtures/#{fixture}", File.dirname(__FILE__)
end

def fixture(fixture)
  File.open(fixture_path(fixture)).read
end

def temp_repo
  File.expand_path(File.join('spec/fixtures/working.git'))
end

def octokit_version
  Gem.loaded_specs['octokit'].version
end

def tmpdir
  File.expand_path '../tmp', File.dirname(__FILE__)
end

def setup_tmpdir
  FileUtils.rm_rf tmpdir
  FileUtils.mkdir tmpdir
end

# Intercept HTTP request to fetch an installation access token from the GitHub
# API, and provide a response that includes the access token used by the VCR
# cassettes.
def stub_request_for_installation_token
  self.extend WebMock::API
   stub_request(:post,
    "https://api.github.com/app/installations/#{ENV["INSTALLATION_ID"]}/access_tokens").
    to_return(
      status: 201,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' },
      body: %Q({
        "token": "47b0a82c8819bfe66fa88568b9a93dc9b4a8867c",
        "expires_at": "#{Time.now.utc.xmlschema}"
      }))
end
