#!/usr/bin/env ruby
# $Id$
require 'test/unit'

# Test TraceLineNumbers module
class TestLineNumbers2 < Test::Unit::TestCase
  @@TEST_DIR = File.expand_path(File.dirname(__FILE__))
  @@TOP_SRC_DIR = File.join(@@TEST_DIR, '..')
  require File.join(@@TOP_SRC_DIR, 'lib', 'tracelines.rb')
  
  def test_all_lnum_data
    test_dir = File.join(@@TEST_DIR, 'data')
    Dir.chdir(test_dir) do 
      Dir.glob('*.rb').sort.each do |f|
        if f =~ /match3/
          puts "Need to consider from match3.rb on"
          break
        end
        fp = File.open(f, 'r')
        lines = fp.read
        fp.rewind
        first_line = fp.readline.chomp
        fp.close()
        expected_str = first_line[1..-1]
        begin
          expected_lnums = eval(expected_str, binding, __FILE__, __LINE__)
        rescue
          assert nil, "Failed reading expected values from #{f}"
        else
          got_lnums = TraceLineNumbers.lnums_for_str(lines)
          assert_equal(expected_lnums, got_lnums)
        end
      end
    end
  end
end
