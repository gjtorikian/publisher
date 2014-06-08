require 'git'

class CloneJob
  @queue = :default

  def self.perform(tmpdir, token, repo)
    clone_repo(repo, token, tmpdir)
    # Dir.chdir "#{tmpdir}/#{destination_repo}" do
    #   setup_git
    #   branchname, message = update_repo(originating_repo, is_public, token)
    #   return message if branchname.nil?
    #   puts "Working on branch #{branchname}"
    #   client = Octokit::Client.new(:access_token => token)
    #   new_pr = client.create_pull_request(destination_repo, "master", branchname, "Sync changes from upstream repository", ":zap::zap::zap:")
    #   puts "PR ##{new_pr[:number]} created"
    #   sleep 2 # seems that the PR cannot be merged immediately after it's made?
    #   # don't merge PRs with empty changesets
    #   if client.pull_request(destination_repo, new_pr[:number])[:changed_files] == 0
    #     client.close_pull_request(destination_repo, new_pr[:number])
    #     puts "Closed PR ##{new_pr[:number]} (empty changeset)"
    #   else
    #     client.merge_pull_request(destination_repo, new_pr[:number].to_i)
    #     puts "Merged PR ##{new_pr[:number]}"
    #   end
    #   client.delete_branch(destination_repo, branchname)
    #   puts "Deleted branch #{branchname}"
    # end
  end

  def self.clone_repo(destination_repo, token, tmpdir)
    puts "Cloning #{destination_repo}..."
    @git_dir = Git.clone(clone_url_with_token(token, destination_repo), "#{tmpdir}/#{destination_repo}")
  end

  def self.setup_git
   @git_dir.config('user.name', 'Hubot')
   @git_dir.config('user.email', 'cwanstrath+hubot@gmail.com')
  end

  def self.print_blocking_output(command)
    while (line = command.gets) # intentionally blocking call
      print line
    end
  end

  def self.clone_url_with_token(token, repo)
    "https://#{token}:x-oauth-basic@github.com/#{repo}.git"
  end
end
