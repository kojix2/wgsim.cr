require "./mutation_options"
require "./sequence_options"

module Wgsim
  struct Options
    property command : String = ""
    property seed : UInt64?
    property mut : MutationOptions = MutationOptions.new
    property seq : SequenceOptions = SequenceOptions.new
  end
end
