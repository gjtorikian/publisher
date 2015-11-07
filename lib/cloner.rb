require 'open3'

class Cloner
  GITHUB_DOMAIN = 'github.com'

  DEFAULTS = {
    :tmpdir               => nil,
    :sha                  => nil,
    :originating_hostname => GITHUB_DOMAIN,
    :originating_repo     => nil,
    :git                  => nil
  }

  attr_accessor :tmpdir, :sha, :originating_hostname, :originating_repo

  def initialize(options)
    logger.level = Logger::WARN if ENV['RACK_ENV'] == 'test'
    logger.info 'New Cloner instance initialized'

    DEFAULTS.each { |key, value| instance_variable_set("@#{key}", options[key] || value) }
    @tmpdir ||= Dir.mktmpdir('publisher')

    if originating_hostname != GITHUB_DOMAIN
      Octokit.configure do |c|
        c.api_endpoint = "https://#{originating_hostname}/api/v3/"
        c.web_endpoint = "https://#{originating_hostname}"
      end
    end

    git_init

    DEFAULTS.each { |key, _| logger.info "  * #{key}: #{instance_variable_get("@#{key}")}" }
  end

  def clone
    Bundler.with_clean_env do
      Dir.chdir "#{tmpdir}/#{originating_repo}" do
        add_remote
        fetch
        checkout
        install
        build_docs
        logger.info 'Published!'
      end
    end
  rescue StandardError => e
    logger.warn e
    raise
  ensure
    FileUtils.rm_rf(tmpdir)
    logger.info "Cleaning up #{tmpdir}"
  end

  def originating_token
    @originating_token ||= (originating_hostname == GITHUB_DOMAIN ? dotcom_token : ghe_token)
  end

  def dotcom_token
    ENV['DOTCOM_MACHINE_USER_TOKEN']
  end

  def ghe_token
    ENV['GHE_MACHINE_USER_TOKEN']
  end

  def remote_name
    @remote_name ||= "otherrepo-#{Time.now.to_i}"
  end

  def url_with_token
    @url_with_token ||= "https://#{originating_token}:x-oauth-basic@#{originating_hostname}/#{originating_repo}.git"
  end

  # Plumbing methods

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def client
    @client ||= Octokit::Client.new(:access_token => originating_token)
  end

  def git
    @git ||= begin
      logger.info "Cloning #{originating_repo} from #{originating_hostname}..."
      logger.info `git clone #{url_with_token} #{tmpdir}/#{originating_repo} --depth 1`
      Git.open "#{tmpdir}/#{originating_repo}"
    end
  end

  def run_command(*args)
    logger.info "Running command #{args.join(' ')}"
    output = status = nil
    output, status = Open3.capture2e(*args)
    output = output.gsub(/#{dotcom_token}/, '<TOKEN>') if dotcom_token
    logger.info "Result: #{output}"
    if status != 0
      report_error(output)
      fail "Command `#{args.join(' ')}` failed: #{output}"
    end
    output
  end

  def report_error(command_output)
    body = "Hey, I'm really sorry about this, but there was some kind of error "
    body << "when I tried to build from #{sha}:\n"
    body << "\n```\n"
    body << command_output
    body << "\n```\n"
    body << "You'll have to resolve this problem manually, I'm afraid.\n"
    body << "![I'm so sorry](http://media.giphy.com/media/NxKcqJI6MdIgo/giphy.gif)"
    client.create_issue originating_repo, '[Publisher] Error detected', body
  end

  # Methods that perform sync actions, in order

  def git_init
    git.config('user.name',  ENV['MACHINE_USER_NAME'])
    git.config('user.email', ENV['MACHINE_USER_EMAIL'])
  end

  def add_remote
    logger.info "Adding remote for #{originating_repo} on #{originating_hostname}..."
    git.add_remote(remote_name, url_with_token)
  end

  def fetch
    logger.info "Fetching #{originating_repo}..."
    git.remote(remote_name).fetch
  end

  def branch_name
    'master'
  end

  def checkout
    logger.info "Checking out #{branch_name}"
    git.branch(branch_name).checkout
  end

  def install
    begin
      logger.info 'Installing dependencies...'
      logger.info `script/bootstrap`
    rescue StandardError => error
      logger.error "Couldn\'t install dependencies! #{error}"
    end
  end

  def build_docs
    logger.info "Publishin'..."
    logger.info `bundle exec rake publish[true]`
  end
end
