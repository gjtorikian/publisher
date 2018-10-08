require 'spec_helper'

describe 'endpoints' do
  let(:helpers) { TestHelper.new }
  let(:incoming) { fixture('incoming.json') }
  let(:non_master_payload) { incoming.sub('refs/heads/master', 'refs/heads/gh-pages') }

  before do
    allow_any_instance_of(app).to receive(:signatures_match?).and_return(true)
    ResqueSpec.reset!
  end

  describe 'sync' do
    it 'does nothing without a body' do
      expect(app).to_not receive(:process_payload)
      post '/build'
      expect(last_response.status).to eql(400)
      expect(last_response.body).to eql('Missing body payload!')
    end

    it 'does nothing if payload is not for master' do
      expect(app).to_not receive(:process_payload)
      post '/build', non_master_payload
      expect(last_response.status).to eql(202)
      expect(last_response.body).to eql('Payload was not for master, was for refs/heads/gh-pages, aborting.')
    end

    it 'can work' do
      stub_request_for_installation_token
      post '/build', incoming
      expect(last_response.status).to eql(200)
      expect(BuildJob).to have_queue_size_of(1)
    end
  end
end
