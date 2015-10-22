require 'fileutils'
require_relative './build_job'

module Helpers
  def signatures_match?(payload_body, github_signature)
    return true if Sinatra::Base.development?
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
    Rack::Utils.secure_compare(signature, github_signature)
  end

  def process_payload(payload)
    @originating_repo = "#{payload['repository']['owner']['name']}/#{payload['repository']['name']}"
    @originating_hostname = payload['repository']['url'].match(%r{//(.+?)/})[1]
    @sha = payload['after']
  end

  def master_branch?(payload)
    payload['ref'] == 'refs/heads/master'
  end
end
