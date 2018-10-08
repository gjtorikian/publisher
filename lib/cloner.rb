require 'open3'

class Cloner
  GITHUB_DOMAIN = 'github.com'

  DEFAULTS = {
    :app_client           => nil,
    :tmpdir               => nil,
    :committers           => [],
    :sha                  => nil,
    :originating_hostname => GITHUB_DOMAIN,
    :originating_repo     => nil,
    :cc_on_error          => [],
    :git                  => nil
  }

  attr_accessor :app_client, :tmpdir, :committers, :sha, :originating_hostname, :originating_repo, :cc_on_error

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

  def app_client_token
    @app_client_token ||= @app_client.access_token
  end

  def remote_name
    @remote_name ||= "otherrepo-#{Time.now.to_i}"
  end

  def url_with_token
    @url_with_token ||= "https://#{app_client_token}:x-oauth-basic@#{originating_hostname}/#{originating_repo}.git"
  end

  # Plumbing methods

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def client
    @client ||= Octokit::Client.new(access_token: app_client_token)
  end

  def git
    @git ||= begin
      logger.info "Cloning #{originating_repo} from #{originating_hostname}..."
      # intentionally not logged to not leak token
      `git clone #{url_with_token} #{tmpdir}/#{originating_repo} --depth 1`
      Git.open "#{tmpdir}/#{originating_repo}"
    end
  end

  def run_command(*args)
    logger.info "Running command #{args.join(' ')}"
    output, status = Open3.capture2e({'BUILD_SHA' => sha}, *args)
    output = output.gsub(/#{app_client_token}/, '<TOKEN>')
    logger.info "Result: #{output}"
    if status != 0
      report_error(args.join(' '), output)
      fail "Command `#{args.join(' ')}` failed: #{output}"
    end
    output
  end

  def report_error(command, command_output)
    body = <<~MARKDOWN
    Hey, I'm really sorry about this, but there was some kind of error when I tried to publish the last time, from #{sha}:

    ```
    #{command}
    #{command_output}
    ```

    You'll have to resolve this problem manually, I'm afraid.

    ![I'm sorry](http://pa1.narvii.com/5910/2c8b457dd08a3ff9e09680168960288a6882991c_hq.gif)
    MARKDOWN


    if committers.any? or cc_on_error.any?
      body << <<~MARKDOWN

      /cc #{committers.join(' ')} #{cc_on_error.join(' ')}
      MARKDOWN
    end

    client.create_issue originating_repo, "Publisher failed to publish #{sha[0..6]}", body
  end

  def git_init
    git.config('user.name',  ENV['MACHINE_USER_NAME'])
    git.config('user.email', ENV['MACHINE_USER_EMAIL'])
  end

  def install
    logger.info 'Installing dependencies...'
    run_command 'script/bootstrap'
  end

  def build_docs
    fetch_pages
    logger.info "Publishin'..."
    run_command 'bundle', 'exec', 'rake', 'publish[true]'
  end

  # necessary because of the shallow clone
  def fetch_pages
    run_command 'git', 'fetch', 'origin', 'gh-pages:gh-pages', '--depth', '1'
  end
end
