class OptionParser
  private def append_flag(flag, description)
    indent = " " * 37
    description = description.gsub("\n", "\n#{indent}")
    if flag.size >= 13
      @flags << "    #{flag}\n#{indent}#{description}"
    else
      @flags << "    #{flag}#{" " * (13 - flag.size)}#{description}"
    end
  end
end
