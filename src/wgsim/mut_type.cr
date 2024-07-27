module Wgsim
  enum MutType : UInt8
    NOCHANGE   = 0
    SUBSTITUTE = 1
    DELETE     = 2
    INSERT     = 3

    # Future work

    # INSERT_SEQ = 4
    # TRANSLOCATE = 5
    # FUSION = 6
  end
end
