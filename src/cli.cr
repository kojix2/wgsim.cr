require "./wgsim"

begin
  Wgsim::CLI.new.run
rescue exception
  STDERR.puts "[wgsim.cr] ERROR: #{exception.class} #{exception.message}"
  STDERR.puts exception.backtrace.join("\n") if Wgsim::CLI.debug
  exit 1
end
