# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'fastlane', '2.196.0'
gem 'cocoapods', '1.11.2'
gem 'synx', '0.2.1'
gem 'dotenv', '2.7.6'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
