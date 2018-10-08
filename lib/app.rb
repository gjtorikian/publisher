# frozen_string_literal: true

begin
  require 'dotenv'
  require 'awesome_print'
  require 'pry-byebug'
rescue LoadError
end

require 'sinatra/base'
require 'json'
require 'redis'
require 'openssl'
require 'base64'

require_relative '../config/redis'
require_relative '../config/app_client'
require_relative './helpers'
require_relative './cloner'

class Publisher < Sinatra::Base
  set :root, File.dirname(__FILE__)
  Dotenv.load if Sinatra::Base.development?

  configure do
    configure_redis
  end

  get '/' do
    'See https://github.com/gjtorikian/publisher for documentation'
  end

  post '/build' do
    # trim trailing slashes
    request.path_info.sub! %r{/$}, ''

    # ensure there's a payload
    request.body.rewind
    payload_body = request.body.read.to_s
    halt 400, 'Missing body payload!' if payload_body.nil? || payload_body.empty?

    # ensure signature is correct
    github_signature = request.env['HTTP_X_HUB_SIGNATURE']
    halt 400, 'Signatures didn\'t match!' unless signatures_match?(payload_body, github_signature)

    @payload = JSON.parse(payload_body)
    halt 202, "Payload was not for master, was for #{@payload['ref']}, aborting." unless master_branch?(@payload)

    # keep some important vars
    process_payload(@payload)

    # query parameter specifying additional users or teams to ping in the error issue.
    @cc_on_error = params[:cc_on_error].split(',').map { |user_or_team| "@#{user_or_team}" } if params[:cc_on_error]

    @app_client = configure_app_client
    Resque.enqueue(BuildJob, @app_client, @committer, @sha, @originating_hostname, @originating_repo, @cc_on_error)
  end

  helpers Helpers
end
