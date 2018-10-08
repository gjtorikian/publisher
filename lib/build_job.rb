# frozen_string_literal: true

require 'git'
require 'octokit'
require_relative 'cloner'

class BuildJob
  @queue = :default

  def self.perform(app_client, committers, sha, originating_hostname, originating_repo, cc_on_error)
    cloner = Cloner.new({
      app_client: app_client,
      committers: committers,
      sha: sha,
      originating_hostname: originating_hostname,
      originating_repo: originating_repo,
      cc_on_error: cc_on_error
    })

    cloner.clone
  end
end
