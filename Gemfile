source 'https://rubygems.org'
ruby '2.4.0'

gem 'git', '~> 1.2'
gem 'json', '~> 1.8'
gem 'jwt', '~> 2.0'
gem 'nokogiri', '~> 1.8'
gem 'octokit', '~> 4.2'
gem 'rake'
gem 'resque', '~> 1.25'
gem 'sinatra', '~> 1.4'
gem 'unicorn', '~> 4.8'

group :development do
  gem 'dotenv', '~> 0.11'
  gem 'foreman', '~> 0.71'
end

group :test do
  gem 'rack-test', '~> 0.6'
  gem 'resque_spec', '~> 0.16.0'
  gem 'rspec', '~> 3.1'
  gem 'webmock', '~> 1.2'
end

group :development, :test do
  gem 'awesome_print'
  gem 'pry-byebug'
  gem 'rubocop'
  gem 'rubocop-github'
end
