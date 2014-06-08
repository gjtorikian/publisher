source 'https://rubygems.org'
ruby '2.0.0'

gem 'sinatra', '1.4.2'
gem 'unicorn', "~> 4.8"
gem 'json', '~> 1.7.7'
gem 'rake'
gem 'git', '~> 1.2.6'

# gems used by developer.github.com
# the reason we do this instead of building the site within Bundler.with_clean_env
# is simply because asking Heroku to install the site's gems takes so long, the
# webhook call fails. it seems better to just (needlessly) group them with this
# app, so that it can be responsible for executing nanoc etc.
group :production, :development do
  gem 'builder'
  gem 'coderay'
  gem 'kramdown', '~> 0.13.2'
  gem 'mime-types', '~> 1.16'
  gem 'nanoc', '~> 3.4.3'
  gem 'nokogiri', '~> 1.6.0'
  gem "pygments.rb", "= 0.1.3"
  gem 'yajl-ruby', '~> 0.8.2'
  gem "rubypython", "0.5.1"
end

group :development do
  gem 'shotgun', '0.9'
end
