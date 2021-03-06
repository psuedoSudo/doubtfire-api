source 'https://rubygems.org'
ruby '2.0.0'

# The venerable, almighty Rails
gem 'rails', '4.0.3'

# This is how we get creative
gem 'populator'
gem 'faker'

# Auth
gem 'devise', '~> 3.1.2'
gem 'devise_ldap_authenticatable'
# gem 'cancan'
gem 'attr_encrypted', '~> 1.3.2'

gem 'grape', '0.6.1'
gem 'grape-active_model_serializers', '~> 1.0.0'
gem 'grape-swagger'

gem 'rack-cors', require: 'rack/cors'

gem 'ci_reporter'

gem 'terminator'

group :development, :replica do
  gem 'pg'
  gem 'hirb'
  gem 'better_errors'
  gem 'rails_best_practices'
  gem 'thin'
end

group :test do
  gem 'simplecov'
  gem 'capybara'
  gem 'launchy'
end

group :production do
  gem 'passenger', '= 4.0.42'
end

group :production, :test, :replica do
  gem 'mysql2'
end

group :development, :test, :replica do
  gem 'rspec-rails', '~> 3'
  gem 'factory_girl_rails'
end

# Student submission
gem 'coderay'
gem 'ruby-filemagic'
gem 'rmagick', '~> 2.15' #require: false #already included in other gems - remove to avoid duplicate errors
gem 'pdfkit'
gem 'wkhtmltopdf-binary-11' #too old!
gem 'pdftk'
gem 'rubyzip'

# Plagarism detection
gem 'moss_ruby', '= 1.1.2'

# Latex
gem 'rails-latex', '=1.0.13'
