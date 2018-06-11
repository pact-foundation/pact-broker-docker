require 'conventional_changelog'
require 'rspec/core'
require 'rspec/core/rake_task'

task :generate_changelog do
  ConventionalChangelog::Generator.new.generate! version: ENV.fetch('TAG')
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
