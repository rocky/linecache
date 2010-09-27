#!/usr/bin/env ruby


## FIXME: CompiledMethod#lines doesn't seem to give lines for 
## embedded methods, It also somethimes gives line number beyond the
## end of the file. That's why we have the select at the end. However

## if the file has comments at the end we won't be able to detect this.

module TraceLineNumbers
  # Return an array of lines numbers that could be 
  # stopped at given a file name of a Ruby program.
  def lnums_for_file(file)
    n = File.open(file).readlines.size
    Rubinius::Compiler.compile_file(file).lines.select{|i| i <= n}.sort
  end
  module_function :lnums_for_file

  # Return an array of lines numbers that could be 
  # stopped at given a file name of a Ruby program.
  # We assume the each line has \n at the end. If not 
  # set the newline parameters to \n.
  def lnums_for_str_array(string_array, newline='')
    n = string_array.size
    str = string_array.join(newline)
    Rubinius::Compiler.compile_string(str).lines.select{|i| i <= n}.sort
  end
  module_function :lnums_for_str_array

  def lnums_for_str(str)
    n = str.split("\n").size
    Rubinius::Compiler.compile_string(str).lines.select{|i| i <= n}.sort
  end

  module_function :lnums_for_str
end

if __FILE__ == $0
  # test_file = '../test/rcov-bug.rb'
  test_file = File.join %W(#{File.dirname(__FILE__)} 
                           ../test/data/begin1.rb)
  puts TraceLineNumbers.lnums_for_file(test_file).inspect 
end
