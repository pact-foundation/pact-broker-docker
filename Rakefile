require 'conventional_changelog'

task :generate_changelog do
  ConventionalChangelog::Generator.new.generate! version: ENV.fetch('TAG')
end
