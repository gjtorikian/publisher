# frozen_string_literal: true

require 'spec_helper'

describe 'Cloner' do
  let(:installation) {
    stub_request_for_installation_token
    Installation.new(ENV['INSTALLATION_ID'])
  }
  let(:cloner) { Cloner.new({
      app_client: Octokit::Client.new(access_token: installation.current_token),
      originating_repo: 'gjtorikian/originating_repo',
      git: Git.clone(fixture_path('gjtorikian/destination_repo'), "#{tmpdir}/gjtorikian/destination_repo"),
      sha: 'e1b5d8d5a3e067d2127b78c75f2430c5f7442826',
      tmpdir: tmpdir
  })}
  let (:app_client_token) {
    cloner.app_client.access_token
  }
  before do
    setup_tmpdir
  end

  it 'creates the originating url with token' do
    expected = "https://#{app_client_token}:x-oauth-basic@github.com/gjtorikian/originating_repo.git"
    expect(cloner.url_with_token).to eql(expected)
  end

  it 'creates the remote name' do
    expect(cloner.remote_name).to match(/otherrepo-[\d]+/)
  end

  it 'initializes octokit' do
    expect(cloner.client.class).to eql(Octokit::Client)
    expect(cloner.client.api_endpoint).to eql('https://api.github.com/')
    expect(cloner.client.access_token).to eql(app_client_token)
  end

  it 'clones the repo' do
    expect(cloner.git.class).to eql(Git::Base)
    expect(Dir.exist?("#{tmpdir}/gjtorikian/destination_repo")).to eql(true)
  end

  it 'runs a command' do
    expect(cloner.run_command('echo', 'foo')).to eql("foo\n")
  end

  it 'reports errors' do
    stub = stub_request(:post, 'https://api.github.com/repos/gjtorikian/originating_repo/issues').
         with(body: "{\"labels\":[],\"title\":\"Publisher failed to publish e1b5d8d\",\"body\":\"Hey, I'm really sorry about this, but there was some kind of error when I tried to publish the last time, from e1b5d8d5a3e067d2127b78c75f2430c5f7442826:\\n\\n```\\necho foo bar\\nfoo\\nMerge error\\nbar\\n```\\n\\nYou'll have to resolve this problem manually, I'm afraid.\\n\\n![I'm sorry](http://pa1.narvii.com/5910/2c8b457dd08a3ff9e09680168960288a6882991c_hq.gif)\\n\"}").
         to_return(status: 204, body: '', headers: {})

    command = 'echo foo bar'
    output = "foo\nMerge error\nbar"

    cloner.report_error(command, output)
    expect(stub).to have_been_requested
  end

  it "reports errors with committers cc'd" do
    cloner.committers = ['@nuclearsandwich', '@gjtorikian']
    stub = stub_request(:post, 'https://api.github.com/repos/gjtorikian/originating_repo/issues').
         with(body: "{\"labels\":[],\"title\":\"Publisher failed to publish e1b5d8d\",\"body\":\"Hey, I'm really sorry about this, but there was some kind of error when I tried to publish the last time, from e1b5d8d5a3e067d2127b78c75f2430c5f7442826:\\n\\n```\\necho foo bar\\nfoo\\nMerge error\\nbar\\n```\\n\\nYou'll have to resolve this problem manually, I'm afraid.\\n\\n![I'm sorry](http://pa1.narvii.com/5910/2c8b457dd08a3ff9e09680168960288a6882991c_hq.gif)\\n\\n\\n/cc @nuclearsandwich @gjtorikian \\n\"}",
              headers: {'Accept'=>'application/vnd.github.v3+json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token 47b0a82c8819bfe66fa88568b9a93dc9b4a8867c', 'Content-Type'=>'application/json', 'User-Agent'=>'Octokit Ruby Gem 4.12.0'}).
         to_return(status: 204, body: '', headers: {})

    command = 'echo foo bar'
    output = "foo\nMerge error\nbar"

    cloner.report_error(command, output)
    expect(stub).to have_been_requested
  end

  it "cc's teams that want to know about errors" do
    cloner.cc_on_error = ['@github/support-tools']
    stub = stub_request(:post, 'https://api.github.com/repos/gjtorikian/originating_repo/issues').
         with(body: "{\"labels\":[],\"title\":\"Publisher failed to publish e1b5d8d\",\"body\":\"Hey, I'm really sorry about this, but there was some kind of error when I tried to publish the last time, from e1b5d8d5a3e067d2127b78c75f2430c5f7442826:\\n\\n```\\necho foo bar\\nfoo\\nMerge error\\nbar\\n```\\n\\nYou'll have to resolve this problem manually, I'm afraid.\\n\\n![I'm sorry](http://pa1.narvii.com/5910/2c8b457dd08a3ff9e09680168960288a6882991c_hq.gif)\\n\\n\\n/cc  @github/support-tools\\n\"}",
              headers: {'Accept'=>'application/vnd.github.v3+json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token 47b0a82c8819bfe66fa88568b9a93dc9b4a8867c', 'Content-Type'=>'application/json', 'User-Agent'=>'Octokit Ruby Gem 4.12.0'}).
         to_return(status: 204, body: '', headers: {})

    command = 'echo foo bar'
    output = "foo\nMerge error\nbar"

    cloner.report_error(command, output)
    expect(stub).to have_been_requested
  end

  it "cc's teams and committers together" do
    cloner.committers = ['@nuclearsandwich', '@gjtorikian']
    cloner.cc_on_error = ['@github/support-tools', '@nuclearsandwich']
    stub = stub_request(:post, 'https://api.github.com/repos/gjtorikian/originating_repo/issues').
         with(body: "{\"labels\":[],\"title\":\"Publisher failed to publish e1b5d8d\",\"body\":\"Hey, I'm really sorry about this, but there was some kind of error when I tried to publish the last time, from e1b5d8d5a3e067d2127b78c75f2430c5f7442826:\\n\\n```\\necho foo bar\\nfoo\\nMerge error\\nbar\\n```\\n\\nYou'll have to resolve this problem manually, I'm afraid.\\n\\n![I'm sorry](http://pa1.narvii.com/5910/2c8b457dd08a3ff9e09680168960288a6882991c_hq.gif)\\n\\n\\n/cc @nuclearsandwich @gjtorikian @github/support-tools @nuclearsandwich\\n\"}",
              headers: {'Accept'=>'application/vnd.github.v3+json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token 47b0a82c8819bfe66fa88568b9a93dc9b4a8867c', 'Content-Type'=>'application/json', 'User-Agent'=>'Octokit Ruby Gem 4.12.0'}).
         to_return(status: 204, body: '', headers: {})

    command = 'echo foo bar'
    output = "foo\nMerge error\nbar"

    cloner.report_error(command, output)
    expect(stub).to have_been_requested
  end
end
