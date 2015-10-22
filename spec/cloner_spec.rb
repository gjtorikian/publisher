require 'spec_helper'

describe 'Cloner' do

  let(:cloner) { Cloner.new({
      :originating_repo  => "gjtorikian/originating_repo",
      :git               => Git.clone( fixture_path("gjtorikian/destination_repo"), "#{tmpdir}/gjtorikian/destination_repo"),
      :tmpdir            => tmpdir
  })}

  before do
    setup_tmpdir
  end

  it "knows the originating token" do
    with_env "DOTCOM_MACHINE_USER_TOKEN", "dotcom_token" do
      expect(cloner.originating_token).to eql("dotcom_token")
    end
  end

  it "knows the dotcom token" do
    with_env "DOTCOM_MACHINE_USER_TOKEN", "dotcom_token" do
      expect(cloner.dotcom_token).to eql("dotcom_token")
    end
  end

  it "knows the ghe token" do
    with_env "GHE_MACHINE_USER_TOKEN", "ghe_token" do
      expect(cloner.ghe_token).to eql("ghe_token")
    end
  end

  it "creates the originating url with token" do
    with_env "DOTCOM_MACHINE_USER_TOKEN", "dotcom_token" do
      expected = "https://dotcom_token:x-oauth-basic@github.com/gjtorikian/originating_repo.git"
      expect(cloner.url_with_token).to eql(expected)
    end
  end

  it "creates the remote name" do
    expect(cloner.remote_name).to match(/otherrepo-[\d]+/)
  end

  it "initializes octokit" do
    with_env "DOTCOM_MACHINE_USER_TOKEN", "dotcom_token" do
      expect(cloner.client.class).to eql(Octokit::Client)
      expect(cloner.client.api_endpoint).to eql('https://api.github.com/')
      expect(cloner.client.access_token).to eql("dotcom_token")
    end
  end

  it "clones the repo" do
    expect(cloner.git.class).to eql(Git::Base)
    expect(Dir.exists?("#{tmpdir}/gjtorikian/destination_repo")).to eql(true)
  end

  it "runs a command" do
    expect(cloner.run_command("echo", "foo")).to eql("foo\n")
  end

  it "reports errors" do
    stub = stub_request(:post, "https://api.github.com/repos/gjtorikian/originating_repo/issues").
         with(:body => "{\"labels\":null,\"title\":\"[Publisher] Error detected\",\"body\":\"Hey, I'm really sorry about this, but there was some kind of error when I tried to build from :\\n\\n```\\nfoo\\nMerge error\\nbar\\n```\\nYou'll have to resolve this problem manually, I'm afraid.\\n![I'm so sorry](http://media.giphy.com/media/NxKcqJI6MdIgo/giphy.gif)\"}").
         to_return(:status => 204, :body => "", :headers => {})

    output = "foo\nMerge error\nbar"

    cloner.report_error(output)
    expect(stub).to have_been_requested
  end

  it "adds the remote" do
    expect(cloner.git.remotes.count).to eql(1)
    cloner.add_remote
    expect(cloner.git.remotes.count).to eql(2)
  end

  it "fetches the repo" do
    cloner.instance_variable_set("@url_with_token", fixture_path("/gjtorikian/originating_repo"))
    cloner.add_remote
    cloner.fetch
  end
end
