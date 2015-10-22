require 'git'
require 'octokit'
require_relative 'cloner'

class BuildJob
  @queue = :default

  def self.perform(sha, originating_hostname, originating_repo)
    cloner = Cloner.new({
      :sha                   => sha,
      :originating_hostname  => originating_hostname,
      :originating_repo      => originating_repo
    })

    cloner.clone
  end
end
