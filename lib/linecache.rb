#!/usr/bin/env ruby
#   Copyright (C) 2007, 2008, 2009, 2010 Rocky Bernstein <rockyb@rubyforge.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#    02110-1301 USA.
#

# Author::    Rocky Bernstein  (mailto:rockyb@rubyforge.net)
#
# = linecache
# A module to read and cache lines of a Ruby program. 

# == SYNOPSIS
#
# The LineCache module allows one to get any line from any file,
# caching lines of the file on first access to the file. Although the 
# file may be any file, the common use is when the file is a Ruby
# script since parsing of the file is done to figure out where the
# statement boundaries are.
#
# The routines here may be is useful when a small random sets of lines
# are read from a single file, in particular in a debugger to show
# source lines.
#
#
#  require 'linecache'
#  lines = LineCache::getlines('/tmp/myruby.rb')
#  # The following lines have same effect as the above.
#  $: << '/tmp'
#  Dir.chdir('/tmp') {lines = LineCache::getlines('myruby.rb')
#
#  line = LineCache::getline('/tmp/myruby.rb', 6)
#  # Note lines[6] == line (if /tmp/myruby.rb has 6 lines)
#
#  LineCache::clear_file_cache
#  LineCache::clear_file_cache('/tmp/myruby.rb')
#  LineCache::update_cache   # Check for modifications of all cached files.
#
# Some parts of the interface is derived from the Python module of the
# same name.
#

# Defining SCRIPT_LINES__ causes Ruby to cache the lines of files
# it reads. The key the setting of __FILE__ at the time when Ruby does
# its read. LineCache keeps a separate copy of the lines elsewhere
# and never destroys SCRIPT_LINES__
SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

require 'tempfile'
require 'digest/sha1'
require 'set'
require_relative 'tracelines'

# = module LineCache
# A module to read and cache lines of a Ruby program. 
module LineCache
  VERSION = '0.45'
  LineCacheInfo = Struct.new(:stat, :line_numbers, :lines, :path, :sha1) unless
    defined?(LineCacheInfo)
 
  # The file cache. The key is a name as would be given by Ruby for 
  # __FILE__. The value is a LineCacheInfo object. 
  @@file_cache = {} 
  @@iseq_cache = {} 
  
  # Maps a string filename (a String) to a key in @@file_cache (a
  # String).
  #
  # One important use of @@file2file_remap is mapping the a full path
  # of a file into the name stored in @@file_cache or given by Ruby's
  # __FILE__. Applications such as those that get input from users,
  # may want canonicalize a file name before looking it up. This map
  # gives a way to do that.
  #
  # Another related use is when a template system is used.  Here we'll
  # probably want to remap not only the file name but also line
  # ranges. Will probably use this for that, but I'm not sure.
  @@file2file_remap = {} 
  @@file2file_remap_lines = {}

  @@iseq2file = {} 

  def remove_iseq_temps
    @@iseq2file.values.each do |filename|
      File.unlink(filename)
    end
  end
  module_function :remove_iseq_temps
  at_exit { remove_iseq_temps }

  
  # Clear the file cache entirely.
  def clear_file_cache()
    @@file_cache = {}
    @@file2file_remap = {}
    @@file2file_remap_lines = {}
  end
  module_function :clear_file_cache

  # Clear the iseq cache entirely.
  def clear_iseq_cache()
    @@iseq_cache = {}
  end
  module_function :clear_file_cache

  # Return an array of cached file names
  def cached_files()
    @@file_cache.keys
  end
  module_function :cached_files

  # Discard cache entries that are out of date. If +filename+ is +nil+
  # all entries in the file cache +@@file_cache+ are checked.
  # If we don't have stat information about a file, which can happen
  # if the file was read from __SCRIPT_LINES but no corresponding file
  # is found, it will be kept. Return a list of invalidated filenames.
  # nil is returned if a filename was given but not found cached.
  def checkcache(filename=nil, use_script_lines=false)
    
    if !filename
      filenames = @@file_cache.keys()
    elsif @@file_cache.member?(filename)
      filenames = [filename]
    else
      return nil
    end

    result = []
    for filename in filenames
      next unless @@file_cache.member?(filename)
      path = @@file_cache[filename].path
      if File.exist?(path)
        cache_info = @@file_cache[filename].stat
        stat = File.stat(path)
        if cache_info
          if stat && 
              (cache_info.size != stat.size or cache_info.mtime != stat.mtime)
            result << filename
            update_cache(filename, use_script_lines)
          end
        else
          result << filename
          update_cache(filename, use_script_lines)
        end
      end
    end
    return result
  end
  module_function :checkcache

  # Cache iseq if it's not already cached.
  def cache_iseq(iseq, string=nil, sha1=nil)
    if !@@iseq_cache.member?(iseq)
      update_iseq_cache(iseq, string, sha1)
    end
    iseq
  end
  module_function :cache_iseq

  # Cache file name or iseq object if it's not already cached.
  # Return the expanded filename for it in the cache if a filename,
  # or the iseq, or nil if we can't find the file.
  def cache(file_or_iseq, reload_on_change=false)
    if file_or_iseq.kind_of?(String)
      cache_file(file_or_iseq, reload_on_change)
    else
      cache_iseq(file_or_iseq)
    end
  end
  module_function :cache

  # Cache filename if it's not already cached.
  # Return the expanded filename for it in the cache
  # or nil if we can't find the file.
  def cache_file(filename, reload_on_change=false)
    if @@file_cache.member?(filename)
      checkcache(filename) if reload_on_change
    else
      update_cache(filename, true)
    end
    if @@file_cache.member?(filename)
      @@file_cache[filename].path
    else
      nil
    end
  end
  module_function :cache_file
      
  # Return true if file_or_iseq is cached
  def cached?(file_or_iseq)
    if file_or_iseq.kind_of?(String) 
      @@file_cache.member?(map_file(file_or_iseq))
    else 
      cached_iseq?(file_or_iseq)
    end
  end
  module_function :cached?

  def cached_script?(filename)
    SCRIPT_LINES__.member?(map_file(filename))
  end
  module_function :cached_script?
      
  def empty?(filename)
    filename=map_file(filename)
    @@file_cache[filename].lines.empty?
  end
  module_function :empty?

  # Get line +line_number+ from file named +filename+. Return nil if
  # there was a problem. If a file named filename is not found, the
  # function will look for it in the $: array.
  # 
  # Examples:
  # 
  #  lines = LineCache::getline('/tmp/myfile.rb')
  #  # Same as above
  #  $: << '/tmp'
  #  lines = LineCache.getlines('myfile.rb')
  #
  def getline(file_or_iseq, line_number, reload_on_change=true)
    lines = 
      if file_or_iseq.kind_of?(String)
        filename = map_file(file_or_iseq)
        filename, line_number = map_file_line(filename, line_number)
        getlines(filename, reload_on_change)
      else
        iseq_getlines(file_or_iseq)
      end
    if lines and (1..lines.size) === line_number
        return lines[line_number-1]
    else
        return nil
    end
  end
  module_function :getline

  # Read lines of +iseq+ and cache the results. However +iseq+ was
  # previously cached use the results from the cache. Return nil
  # if we can't get lines
  def iseq_getlines(iseq)
    if @@iseq_cache.member?(iseq)
      return @@iseq_cache[iseq].lines
    else
      update_iseq_cache(iseq)
      if @@iseq_cache.member?(iseq)
        return @@iseq_cache[iseq].lines 
      else
        return nil
      end
    end
  end
  module_function :iseq_getlines

  # Read lines of +filename+ and cache the results. However +filename+ was
  # previously cached use the results from the cache. Return nil
  # if we can't get lines
  def getlines(filename, reload_on_change=false)
    filename = map_file(filename)
    checkcache(filename) if reload_on_change
    if @@file_cache.member?(filename)
      return @@file_cache[filename].lines
    else
      update_cache(filename, true)
      if @@file_cache.member?(filename)
        return @@file_cache[filename].lines 
      else
        return nil
      end
    end
  end
  module_function :getlines

  # Return full filename path for filename
  def path(filename)
    return unless filename.kind_of?(String)
    filename = map_file(filename)
    return nil unless @@file_cache.member?(filename)
    @@file_cache[filename].path
  end
  module_function :path

  def remap_file(to_file, from_file)
    @@file2file_remap[to_file] = from_file
  end
  module_function :remap_file

  def remap_file_lines(from_file, to_file, range, start)
    range = (range..range) if range.kind_of?(Fixnum)
    to_file = from_file unless to_file
    if @@file2file_remap_lines[to_file] 
      # FIXME: need to check for overwriting ranges: whether
      # they intersect or one encompasses another.
      @@file2file_remap_lines[to_file] << [from_file, range, start]
    else
      @@file2file_remap_lines[to_file]  = [[from_file, range, start]]
    end
  end
  module_function :remap_file_lines
  
  # Return SHA1 of filename.
  def sha1(filename)
    filename = map_file(filename)
    return nil unless @@file_cache.member?(filename)
    return @@file_cache[filename].sha1.hexdigest if 
      @@file_cache[filename].sha1
    sha1 = Digest::SHA1.new
    @@file_cache[filename].lines.each do |line|
      sha1 << line + "\n"
    end
    @@file_cache[filename].sha1 = sha1
    sha1.hexdigest
  end
  module_function :sha1
      
  # Return the number of lines in filename
  def size(file_or_iseq)
    cache(file_or_iseq)
    if file_or_iseq.kind_of?(String)
      file_or_iseq = map_file(file_or_iseq)
      return nil unless @@file_cache.member?(file_or_iseq)
      @@file_cache[file_or_iseq].lines.length
    else
      return nil unless @@iseq_cache.member?(file_or_iseq)
      @@iseq_cache[file_or_iseq].lines.length
    end
  end
  module_function :size

  # Return File.stat in the cache for filename.
  def stat(filename)
    return nil unless @@file_cache.member?(filename)
    @@file_cache[filename].stat
  end
  module_function :stat

  # Return an Array of breakpoints in filename.
  # The list will contain an entry for each distinct line event call
  # so it is possible (and possibly useful) for a line number appear more
  # than once.
  def trace_line_numbers(filename, reload_on_change=false)
    fullname = cache(filename, reload_on_change)
    return nil unless fullname
    e = @@file_cache[filename]
    unless e.line_numbers
      e.line_numbers = 
        TraceLineNumbers.lnums_for_str_array(e.lines)
      e.line_numbers = false unless e.line_numbers
    end
    e.line_numbers
  end
  module_function :trace_line_numbers
    
  def map_file(file)
    @@file2file_remap[file] ? @@file2file_remap[file] : file
  end
  module_function :map_file

  def map_iseq(iseq)
    if @@iseq2file[iseq] 
      @@iseq2file[iseq] 
    else 
      # Doc says there's new takes an optional string parameter
      # But it doesn't work for me
      sha1 = Digest::SHA1.new
      string = iseq.source
      sha1 << iseq.source
      tempfile = Tempfile.new(["eval-#{sha1.hexdigest[0...7]}-", '.rb'])
      tempfile.open.puts(string)
      tempfile.close
      # cache_iseq(iseq, string, sha1.hexdigest)
      @@iseq2file[iseq] = tempfile.path
      tempfile.path
    end
  end
  module_function :map_iseq

  def map_file_line(file, line)
    if @@file2file_remap_lines[file]
      @@file2file_remap_lines[file].each do |from_file, range, start|
        if range === line
          from_file = from_file || file 
          return [from_file, start+line-range.begin] 
        end
      end
    end
    return [map_file(file), line]
  end
  module_function :map_file_line

  def iseq_is_eval?(iseq)
    !!iseq.source
  end
  module_function :iseq_is_eval?

  # Update a cache entry.  If something is wrong, return nil. Return
  # true if the cache was updated and false if not. 
  def update_iseq_cache(iseq, string=nil, sha1=nil)
    return false unless iseq_is_eval?(iseq)
    string = iseq.source unless string
    @@iseq_cache[iseq] = 
      LineCacheInfo.new(nil, nil, string.split(/\n/), nil, sha1)
    return true
  end
  module_function :update_iseq_cache

  # Update a cache entry.  If something's
  # wrong, return nil. Return true if the cache was updated and false
  # if not.  If use_script_lines is true, use that as the source for the
  # lines of the file
  def update_cache(filename, use_script_lines=false)

    return nil unless filename

    @@file_cache.delete(filename)
    path = File.expand_path(filename)
    
    if File.exist?(path)
      stat = File.stat(path)
    elsif File.basename(filename) == filename
      # try looking through the search path.
      stat = nil
      for dirname in $:
        path = File.join(dirname, filename)
        if File.exist?(path)
            stat = File.stat(path)
            break
        end
      end
      return false unless stat
    end
    begin
      fp = File.open(path, 'r')
      lines = fp.readlines()
      fp.close()
    rescue 
      ##  print '*** cannot open', path, ':', msg
      return nil
    end
    @@file_cache[filename] = LineCacheInfo.new(File.stat(path), nil, lines,
                                               path, nil)
    @@file2file_remap[path] = filename
    return true
  end

  module_function :update_cache
end

# example usage
if __FILE__ == $0 
  def yes_no(var) 
    return var ? "" : "not "
  end

  lines = LineCache::getlines(__FILE__)
  puts "#{__FILE__} has #{LineCache.size(__FILE__)} lines"
  line = LineCache::getline(__FILE__, 6)
  puts "The 6th line is\n#{line}" 
  line = LineCache::remap_file(__FILE__, 'another_name')
  puts LineCache::getline('another_name', 7)

  puts("Files cached: #{LineCache::cached_files.inspect}")
  LineCache::update_cache(__FILE__)
  LineCache::checkcache(__FILE__)
  puts "#{__FILE__} has #{LineCache::size(__FILE__)} lines"
  puts "#{__FILE__} trace line numbers:\n" + 
    "#{LineCache::trace_line_numbers(__FILE__).to_a.sort.inspect}"
  puts("#{__FILE__} is %scached." % 
       yes_no(LineCache::cached?(__FILE__)))
  puts LineCache::stat(__FILE__).inspect
  puts "Full path: #{LineCache::path(__FILE__)}"
  LineCache::checkcache # Check all files in the cache
  LineCache::clear_file_cache 
  puts("#{__FILE__} is now %scached." % 
       yes_no(LineCache::cached?(__FILE__)))
  digest = SCRIPT_LINES__.select{|k,v| k =~ /digest.rb$/}
  puts digest.first[0] if digest
  line = LineCache::getline(__FILE__, 7)
  puts "The 7th line is\n#{line}" 
  LineCache::remap_file_lines(__FILE__, 'test2', (10..20), 6)
  puts LineCache::getline('test2', 10)
  puts "Remapped 10th line of test2 is\n#{line}" 
  require 'thread_frame'
  puts eval("x=1
LineCache::getline(RubyVM::ThreadFrame.current.iseq, 1)")
  puts eval("x=2
LineCache::getline(RubyVM::ThreadFrame.current.iseq, 2)")
end
