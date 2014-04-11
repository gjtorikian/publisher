require 'sinatra/base'
require 'json'
require 'fileutils'
require 'git'
require 'octokit'

class Publisher < Sinatra::Base
  set :root, File.dirname(__FILE__)

  # "Thin is a supremely better performing web server so do please use it!"
  set :server, %w[thin webrick]

  before do
    # trim trailing slashes
    request.path_info.sub! %r{/$}, ''
    pass unless %w[build].include? request.path_info.split('/')[1]
    # keep some important vars
    @payload = JSON.parse params[:payload]
    @repo = "#{@payload["repository"]["owner"]["name"]}/#{@payload["repository"]["name"]}"
    check_params params
  end

  get "/" do
    "I think you misunderstand how to use this."
  end

  post "/build" do
    do_the_work
  end

  helpers do

    def check_params(params)
      return halt 500, "Tokens didn't match!" unless valid_token?(params[:token])
      return halt 202, "Payload was not for master, aborting." unless master_branch?(@payload)
    end

    def valid_token?(token)
      return true if Sinatra::Base.development?
      params[:token] == ENV["BUILD_TOKEN"]
    end

    def token
      ENV["HUBOT_GITHUB_TOKEN"]
    end

    def master_branch?(payload)
      payload["ref"] == "refs/heads/master"
    end

    def do_the_work
      in_tmpdir do |tmpdir|
        clone_repo(tmpdir)
        Dir.chdir "#{tmpdir}/#{@repo}" do
          setup_git
          `bundle exec rake publish`
        end
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

    def clone_repo(tmpdir)
      puts "Cloning #{@repo}..."
      @git_dir = Git.clone(clone_url_with_token(@repo), "#{tmpdir}/#{@repo}")
    end

    def setup_git
     @git_dir.config('user.name', 'Hubot')
     @git_dir.config('user.email', 'cwanstrath+hubot@gmail.com')
    end

    def clone_url_with_token(repo)
      "https://#{token}:x-oauth-basic@github.com/#{repo}.git"
    end
  end
end
