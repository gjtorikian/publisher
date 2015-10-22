require 'git'

class BuildJob
  @queue = :default

  def self.perform(tmpdir, token, repo, lang=nil)
    clone_repo(repo, token, tmpdir)
    Dir.chdir "#{tmpdir}/#{repo}" do
      setup_git
      Bundler.with_clean_env do
        # fetch gh-pages then hop back to master
        puts `git fetch --all`
        @git_dir.branch('gh-pages').checkout
        @git_dir.branch('master').checkout
        puts "Installing gems..."
        puts `bundle install`
        puts "Publishin'..."
        puts `bundle exec rake publish[true]`
        puts "Published!"
      end
    end
  end

  def self.clone_repo(repo, token, tmpdir)
    puts "Cloning #{repo}..."
    @git_dir = Git.clone(clone_url_with_token(token, repo), "#{tmpdir}/#{repo}")
  end

  def self.setup_git
   @git_dir.config('user.name', 'Hubot')
   @git_dir.config('user.email', 'cwanstrath+hubot@gmail.com')
  end

  def self.clone_url_with_token(token, repo)
    "https://#{token}:x-oauth-basic@github.com/#{repo}.git"
  end
end
