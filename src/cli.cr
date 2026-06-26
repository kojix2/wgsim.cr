require "./wgsim"

begin
  Wgsim::CLI.new.run
rescue exception
  Wgsim::Log.exception(exception, debug: Wgsim::CLI.debug?)
  exit 1
end
