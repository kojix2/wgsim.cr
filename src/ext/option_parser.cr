class OptionParser
  macro _on(short_type, desc, field)
      {% short, ctype = short_type.split %}
      {% type = "to_i32" if ctype == "INT" %}
      {% type = "to_u32" if ctype == "UINT" %}
      {% type = "to_i64" if ctype == "INT64" %}
      {% type = "to_u64" if ctype == "UINT64" %}
      {% type = "to_f64" if ctype == "FLOAT" %}
      on("#{{{short}}} #{{{ctype}}}", "#{{{desc}}} [#{config.{{field.id}}}]") do |v|
        begin
          config.{{field.id}} = v.{{type.id}}
        rescue ex
          Utils.print_error! "#{{{short_type}}}: #{ex.message}"
        end
      end
    end

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
