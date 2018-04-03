source 'https://rubygems.org'

gem 'json'

require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)

gem 'github-pages', versions['github-pages']
gem 'jekyll', '~> 3.6'
gem 'jekyll-paginate'
gem 'redcarpet'

group :jekyll_plugins do
  gem 'jekyll-algolia', '~> 1.0'
end
