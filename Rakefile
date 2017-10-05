require 'conventional_changelog'

task :generate_changelog do
  ConventionalChangelog::Generator.new.generate! version: "v#{ENV.fetch('TAG')}"
end
