begin
  require 'dotenv'
rescue LoadError
end

require 'sinatra/base'
require 'json'
require 'redis'
require 'openssl'
require 'base64'

require_relative '../config/redis'
require_relative './helpers'
require_relative './cloner'

class Publisher < Sinatra::Base
  set :root, File.dirname(__FILE__)
  Dotenv.load if Sinatra::Base.development?

  configure do
    configure_redis
  end

  get '/' do
    'I think you misunderstand how to use this.'
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
    @destination_hostname = params[:destination_hostname] || 'github.com'

    Resque.enqueue(BuildJob, @sha, @originating_hostname, @originating_repo)
  end

  helpers Helpers
end
