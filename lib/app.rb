begin
  require 'dotenv'
rescue LoadError
end

require "sinatra/base"
require "json"
require "fileutils"
require "octokit"
require "resque"
require "redis"
require "openssl"
require "base64"

require './build_job'

class Publisher < Sinatra::Base
  set :root, File.dirname(__FILE__)

  configure do
    configure_redis
  end

  before do
    # trim trailing slashes
    request.path_info.sub! %r{/$}, ''
    pass unless %w[build].include? request.path_info.split('/')[1]
    # ensure signature is correct
    request.body.rewind
    payload_body = request.body.read
    verify_signature(payload_body)
    # keep some important vars
    @payload = JSON.parse params[:payload]
    @repo = "#{@payload["repository"]["owner"]["name"]}/#{@payload["repository"]["name"]}"
    @lang = params[:lang]
    check_params params
  end

  get "/" do
    "I think you misunderstand how to use this."
  end

  post "/build" do
    do_the_work
  end

  helpers do

    def verify_signature(payload_body)
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV['SECRET_TOKEN'], payload_body)
      return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    end

    def check_params(params)
      return halt 202, "Payload was not for master, aborting." unless master_branch?(@payload)
    end

    def token
      ENV["MACHINE_USER_TOKEN"]
    end

    def master_branch?(payload)
      payload["ref"] == "refs/heads/master"
    end

    def do_the_work
      in_tmpdir do |tmpdir|
        Resque.enqueue(BuildJob, tmpdir, token, @repo, @lang)
      end
    end

    def in_tmpdir
      path = File.expand_path "#{Dir.tmpdir}/publisher/repos/#{Time.now.to_i}#{rand(1000)}/"
      FileUtils.mkdir_p path
      puts "Directory created at: #{path}"
      yield path
    ensure
      FileUtils.rm_rf( path ) if File.exists?( path ) && !Sinatra::Base.development?
    end
  end
end
