module Wgsim
  module Console
    PREFIX = "[wgsim]"

    def self.info(message : String, io : IO = STDERR) : Nil
      io.puts "#{PREFIX} #{message}"
    end

    def self.warn(message : String, io : IO = STDERR) : Nil
      io.puts "#{PREFIX} WARN: #{message}"
    end

    def self.error(message : String, io : IO = STDERR) : Nil
      io.puts "#{PREFIX} ERROR: #{message}"
    end

    def self.exception(exception : Exception, debug : Bool = false, io : IO = STDERR) : Nil
      message = exception.message
      error("#{exception.class}#{message ? " #{message}" : ""}", io)
      io.puts exception.backtrace.join("\n") if debug
    end

    def self.summary(summary : String, io : IO = STDERR) : Nil
      summary.split('\n').each do |line|
        info("# #{line}", io)
      end
    end
  end
end
