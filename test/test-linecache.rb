#!/usr/bin/env ruby
require 'test/unit'
require 'fileutils'
require 'tempfile'

# require 'rubygems'
# require 'ruby-debug'; Debugger.start

# Test LineCache module
class TestLineCache < Test::Unit::TestCase
  @@TEST_DIR = File.expand_path(File.dirname(__FILE__))
  @@TOP_SRC_DIR = File.join(@@TEST_DIR, '..', 'lib')
  require File.join(@@TOP_SRC_DIR, 'linecache.rb')
  
  def setup
    LineCache::clear_file_cache
  end
  
  def test_basic
    fp = File.open(__FILE__, 'r')
    compare_lines = fp.readlines()
    fp.close
    
    # Test getlines to read this file.
    lines = LineCache::getlines(__FILE__)
    assert_equal(compare_lines, lines,
                 'We should get exactly the same lines as reading this file.')
    
    # Test getline to read this file. The file should now be cached,
    # so internally a different set of routines are used.
    test_line = 1
    line = LineCache::getline(__FILE__, test_line)
    assert_equal(compare_lines[test_line-1], line,
                 'We should get exactly the same line as reading this file.')
    
    # Test getting the line via a relative file name
    Dir.chdir(File.dirname(__FILE__)) do 
      short_file = File.basename(__FILE__)
      test_line = 10
      line = LineCache::getline(short_file, test_line)
      assert_equal(compare_lines[test_line-1], line,
                   'Short filename lookup should work')
    end

    # Write a temporary file; read contents, rewrite it and check that
    # we get a change when calling getline.
    tf = Tempfile.new("testing")
    test_string = "Now is the time.\n"
    tf.puts(test_string)
    tf.close
    line = LineCache::getline(tf.path, 1)
    assert_equal(test_string, line,
                 "C'mon - a simple line test like this worked before.")
    tf.open
    test_string = "Now is another time.\n"
    tf.puts(test_string)
    tf.close
    LineCache::checkcache
    line = LineCache::getline(tf.path, 1)
    assert_equal(test_string, line,
                 "checkcache should have reread the temporary file.")
    FileUtils.rm tf.path

    LineCache::update_cache(__FILE__)
    LineCache::clear_file_cache
  end

  def test_cached
    LineCache::clear_file_cache
    assert_equal(false, LineCache::cached?(__FILE__),
                 "file #{__FILE__} shouldn't be cached - just cleared cache.")
    line = LineCache::getline(__FILE__, 1)
    assert line
    assert_equal(true, LineCache::cached?(__FILE__),
                 "file #{__FILE__} should now be cached")
    assert_equal(false, LineCache::cached_script?('./short-file'),
                 "Should not find './short-file' in SCRIPT_LINES__")
    Dir.chdir(File.dirname(__FILE__)) do 
      load('./short-file', 0)
      puts SCRIPT_LINES__.keys.inspect
      assert_equal(true, LineCache::cached_script?('./short-file'),
                   "Should be able to find './short-file' in SCRIPT_LINES__")
    end
  end

  def test_stat
    assert_equal(nil, LineCache::stat(__FILE__),
                 "stat for #{__FILE__} shouldn't be nil - just cleared cache.")
    line = LineCache::getline(__FILE__, 1)
    assert line
    assert(LineCache::stat(__FILE__),
           "file #{__FILE__} should now have a stat")
  end

  def test_path
    assert_equal(nil, LineCache::path(__FILE__),
                 "path for #{__FILE__} shouldn't be nil - just cleared cache.")
    path = LineCache::cache(__FILE__)
    assert path
    assert_equal(path, LineCache::path(__FILE__),
           "path of #{__FILE__} should be the same as we got before")
  end

  def test_sha1
    test_file = File.join(@@TEST_DIR, 'short-file') 
    LineCache::cache(test_file)
    assert_equal('1134f95ea84a3dcc67d7d1bf41390ee1a03af6d2',
                 LineCache::sha1(test_file))
  end

end
