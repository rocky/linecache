#!/usr/bin/env ruby

module TraceLineNumbers
  # Get line numbers for CompiledMethod.method#lines
  # format is: ip line ip line ...
  # Odd numbers then are the line numbers
  def lnums_for_lines(lines)
    odds = (0...lines.size/2).map{|i| i*2+1}
    lines.to_a.values_at(*odds).sort
  end
  module_function :lnums_for_lines

  def compiled_methods(cm)
    result = [cm]
    result += cm.child_methods.map{|child| compiled_methods(child)}.flatten 
    result
  end      
  module_function :compiled_methods

  def lnums_for_compiled_methods(compiled_method)
    compiled_methods = compiled_methods(compiled_method)
    compiled_methods.map { |cm| lnums_for_lines(cm.lines) }.flatten.sort
  end
  module_function :lnums_for_compiled_methods

  # Return an array of lines numbers that could be 
  # stopped at given a file name of a Ruby program.
  def lnums_for_file(file)
    lnums_for_compiled_methods(Rubinius::Compiler.compile_file(file))
  end
  module_function :lnums_for_file

  # Return an array of lines numbers that could be 
  # stopped at given a file name of a Ruby program.
  # We assume the each line has \n at the end. If not 
  # set the newline parameters to \n.
  def lnums_for_str_array(string_array, newline='')
    str = string_array.join(newline)
    lnums_for_str(str)
  end
  module_function :lnums_for_str_array

  def lnums_for_str(str)
    lnums_for_compiled_methods(Rubinius::Compiler.compile_string(str))
  end

  module_function :lnums_for_str
end

if __FILE__ == $0
  # test_file = '../test/rcov-bug.rb'
  test_file = File.join %W(#{File.dirname(__FILE__)} 
                           ../test/data/begin1.rb)
  puts TraceLineNumbers.lnums_for_file(test_file).inspect 
  test_file = File.join %W(#{File.dirname(__FILE__)} 
                           ../test/data/def1.rb)
  puts TraceLineNumbers.lnums_for_file(test_file).inspect 
end
