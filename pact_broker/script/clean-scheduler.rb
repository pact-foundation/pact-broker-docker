#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs the database clean on a cron schedule. Replaces supercronic: the same
# background-process topology, without a vendored Go binary.

require "fugit"

CLEAN_COMMAND = "/usr/local/bin/clean"

$stdout.sync = true

# Signals the whole clean process group. The clean is a shell wrapper around
# two rake tasks, and a shell does not forward signals to its children, so
# signalling the wrapper alone would leave rake running against the database.
def signal_clean(signal, pgid)
  Process.kill(signal, -pgid)
rescue Errno::ESRCH
  # The clean exited between the caller's check and this kill.
end

schedule = ENV["PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE"]
abort("PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE is not set") if schedule.nil? || schedule.empty?

cron = Fugit::Cron.parse(schedule)
abort("Invalid cron schedule: #{schedule.inspect}") if cron.nil?

clean_pgid = nil
terminating = false

%w[TERM INT].each do |signal|
  Signal.trap(signal) do
    terminating = true
    signal_clean(signal, clean_pgid) if clean_pgid
  end
end

puts "Creating schedule #{schedule} to clean database"

until terminating
  now = Time.now
  delay = cron.next_time(now).to_t - now
  sleep(delay) if delay.positive?
  break if terminating

  puts "Running database clean"
  # Spawned rather than loaded in-process, so a failed clean logs and the
  # schedule survives.
  begin
    clean_pgid = Process.spawn(CLEAN_COMMAND, pgroup: true)
  rescue SystemCallError => e
    puts "Database clean could not start: #{e.message}"
    next
  end

  # A signal arriving between the spawn and the assignment found no pid to
  # forward to, so re-check now that there is one.
  signal_clean("TERM", clean_pgid) if terminating

  # Waits for the clean even while terminating, so a shutdown never abandons
  # one mid-transaction.
  _pid, status = Process.wait2(clean_pgid)
  clean_pgid = nil

  if status.signaled?
    puts "Database clean stopped by signal #{Signal.signame(status.termsig)}"
  elsif !status.success?
    puts "Database clean failed with exit status #{status.exitstatus}"
  end
end
