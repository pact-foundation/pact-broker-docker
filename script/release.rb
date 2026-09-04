#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

# git-cliff writes its log lines to stderr. Command runners below capture
# stdout and stderr together, so a noisier default would corrupt version
# parsing; `error` (not `off`) still lets a genuine git-cliff failure surface
# through CommandError, which is built entirely from the captured output.
ENV["RUST_LOG"] ||= "error"

# Release automation for the pact-broker-docker images.
#
# Requires git, gh and git-cliff on PATH. Runnable locally as well as in CI.
class Release
  RELEASE_BRANCH = "release/pact-broker-docker"
  BASE_BRANCH    = "master"
  VERSION_FILE   = "VERSION"
  LOCKFILE       = "pact_broker/Gemfile.lock"
  TAG_PREFIX     = "v"
  IMAGE          = "pactfoundation/pact-broker"

  class CommandError < StandardError; end

  # MARK: Version file

  def self.read_version(path = VERSION_FILE)
    File.read(path).strip
  end

  def self.write_version(version, path = VERSION_FILE)
    File.write(path, version)
  end

  # MARK: Version computation

  # git-cliff prints the bumped tag, e.g. "v2.121.0". Returns nil when there is
  # nothing to release: cliff printed nothing, repeated the current version
  # (every commit since the last tag was skipped, such as chore(deps)), or
  # failed and printed a message.
  def self.normalise_bumped_version(cliff_output, current)
    version = cliff_output.to_s.strip.delete_prefix(TAG_PREFIX)
    return nil unless version.match?(/\A\d+\.\d+\.\d+\z/)
    return nil if version == current

    version
  end

  # MARK: Docker tag

  def self.gem_version(lockfile_content)
    lockfile_content[/^\s*pact_broker \(([^)]+)\)/, 1] or
      raise "Could not find pact_broker in the lockfile"
  end

  def self.docker_tag(version, gem_version)
    "#{version}-pactbroker#{gem_version}"
  end

  # MARK: Compose files

  # The test compose files are excluded: script/test.sh rewrites their image
  # references to the tag under test on every run.
  def self.compose_files
    Dir.glob("./docker-compose*.yml").reject { |path| path.include?("test") }.sort
  end

  # Handles both `image: "pactfoundation/pact-broker:TAG"` and the unquoted
  # form, preserving whichever a line already uses.
  def self.rewrite_image_ref(content, tag)
    content.gsub(/#{Regexp.escape(IMAGE)}:[^"'\s]*/, "#{IMAGE}:#{tag}")
  end

  # MARK: Command runners

  def self.run!(*cmd)
    out, status = Open3.capture2e(*cmd)
    raise CommandError, "Command failed: #{cmd.join(' ')}\n#{out}" unless status.success?

    out.strip
  end

  # Runs a command whose failure is an expected outcome, returning its combined
  # output. Callers inspect the output rather than a status.
  def self.run(*cmd)
    out, = Open3.capture2e(*cmd)
    out.strip
  end

  # MARK: git-cliff

  def self.next_version(current)
    normalise_bumped_version(run!("git", "cliff", "--bumped-version"), current)
  end

  def self.changelog_entry(tag)
    run!("git", "cliff", "--tag", tag, "--unreleased", "--strip", "header")
  end

  def self.prepend_changelog(tag)
    run!("git", "cliff", "--tag", tag, "--unreleased", "--prepend", "CHANGELOG.md")
  end

  # MARK: Subcommands

  def self.prepare(dry_run:)
    current = read_version
    bumped  = next_version(current)

    if bumped.nil?
      puts "No releasable commits since v#{current} — nothing to do."
      return
    end

    tag        = "#{TAG_PREFIX}#{bumped}"
    image_tag  = docker_tag(bumped, gem_version(File.read(LOCKFILE)))
    puts "Preparing release #{tag} (image tag #{image_tag})..."

    write_version(bumped)
    compose_files.each do |path|
      File.write(path, rewrite_image_ref(File.read(path), image_tag))
    end
    prepend_changelog(tag)
    body = changelog_entry(tag)

    if dry_run
      puts "--dry-run: leaving VERSION, CHANGELOG.md and the compose files modified in the working tree."
      puts
      puts body
      return
    end

    run!("git", "checkout", "-B", RELEASE_BRANCH, "origin/#{BASE_BRANCH}")
    run!("git", "add", VERSION_FILE, "CHANGELOG.md", *compose_files)
    run!("git", "commit", "-m", "chore: prepare release #{tag}")
    run!("git", "push", "--force", "origin", RELEASE_BRANCH)

    existing = run("gh", "pr", "list", "--head", RELEASE_BRANCH, "--state", "open",
                   "--json", "number", "--jq", ".[0].number")

    if existing.empty? || existing == "null"
      run!("gh", "pr", "create", "--draft", "--base", BASE_BRANCH, "--head", RELEASE_BRANCH,
           "--title", "chore: release #{tag}", "--body", body)
      puts "Created draft release PR for #{tag}"
    else
      run!("gh", "pr", "edit", existing, "--title", "chore: release #{tag}", "--body", body)
      puts "Updated release PR ##{existing} for #{tag}"
    end
  ensure
    run("git", "checkout", BASE_BRANCH) unless dry_run
  end

  def self.tag_release
    tag = "#{TAG_PREFIX}#{read_version}"

    run!("git", "fetch", "--tags", "origin")
    unless run("git", "tag", "--list", tag).empty?
      puts "Tag #{tag} already exists — nothing to do."
      return
    end

    run!("git", "tag", tag)
    run!("git", "push", "origin", tag)
    puts "Pushed tag #{tag}"
  end

  # MARK: CLI

  USAGE = "Usage: script/release.rb prepare [--dry-run] | tag"

  def self.parse_args(argv)
    command = argv[0]
    flags   = argv[1..] || []
    raise ArgumentError, USAGE unless %w[prepare tag].include?(command)

    dry_run = flags.delete("--dry-run") ? true : false
    raise ArgumentError, USAGE unless flags.empty?
    raise ArgumentError, "--dry-run is only supported by prepare. #{USAGE}" if dry_run && command != "prepare"

    [command.to_sym, dry_run]
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    command, dry_run = Release.parse_args(ARGV)
  rescue ArgumentError => e
    warn e.message
    exit 1
  end

  case command
  when :prepare then Release.prepare(dry_run: dry_run)
  when :tag     then Release.tag_release
  end
end
