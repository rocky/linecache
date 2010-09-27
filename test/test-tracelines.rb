#!/usr/bin/env ruby
# $Id$
require 'test/unit'
require 'fileutils'
require 'tempfile'

# require 'rubygems'
# require 'ruby-debug'; Debugger.init

# Test TestLineNumbers module
class TestLineNumbers1 < Test::Unit::TestCase

  @@TEST_DIR = File.expand_path(File.dirname(__FILE__))
  @@TOP_SRC_DIR = File.join(@@TEST_DIR, '..', 'lib')
  require File.join(@@TOP_SRC_DIR, 'tracelines.rb')

  @@rcov_file = File.join(@@TEST_DIR, 'rcov-bug.rb')
  # File.open(@@rcov_file, 'r') {|fp|
  #   first_line = fp.readline[1..-2]
  #   @@rcov_lnums = eval(first_line, binding, __FILE__, __LINE__)
  # }
  @@rcov_lnums = [0, 0, 3, 5, 6, 7, 8, 10]
  
  def test_for_file
    rcov_lines = TraceLineNumbers.lnums_for_file(@@rcov_file)
    assert_equal(@@rcov_lnums, rcov_lines)
  end

  def test_for_string
    string = "# Some rcov bugs.\nz = \"\nNow is the time\n\"\n\nz =~ \n     /\n      5\n     /ix\n"
    rcov_lines = TraceLineNumbers.lnums_for_str(string)
    puts "FIXME: CompileMethod#lines again"
    check = [0, 0, 2, 4, 6, 6, 8, 9]
    # check = [2, 9]
    assert_equal(check, rcov_lines)
  end

  def test_for_string_array
    lines = File.open(@@rcov_file).readlines
    rcov_lines = 
      TraceLineNumbers.lnums_for_str_array(lines)
    assert_equal(@@rcov_lnums, rcov_lines)
  end
end
