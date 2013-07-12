#!/usr/bin/env rake
# -*- Ruby -*-
# Are we Rubinius? The right versions of it?
raise RuntimeError,
'This package is for Rubinius 1.2.[34] or 2.0.x only!' unless
  Object.constants.include?('Rubinius') &&
  Rubinius.constants.include?('VM') &&
  Rubinius::VERSION =~ /1\.2\.[34]/ || Rubinius::VERSION =~ /2\.0/

require 'rubygems'

ROOT_DIR = File.dirname(__FILE__)
Gemspec_filename = 'rbx-linecache.gemspec'
require File.join %W(#{ROOT_DIR} lib linecache)

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

require 'rubygems/package_task'
desc "Build the gem"
task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build #{Gemspec_filename}"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv gemspec.file_name, 'pkg'

    # Now make a 2.0 package by changing 1.2 to 2.0 in the gemspec
    # and creating another gemspec and moving that accordingly
    lines = File.open(Gemspec_filename).readlines.map{|line|
      line.gsub(/'universal', 'rubinius', '1\.2'/,
                "'universal', 'rubinius', '2.0'");
    }

    two_filename = gemspec.file_name.gsub(/1\.2/, '2.0')
    gemspec_filename2 = "rbx-linecache2.gemspec"
    f = File.open(gemspec_filename2, "w")
    f.write(lines); f.close
    sh "gem build #{gemspec_filename2}"
    FileUtils.mv("#{two_filename}", "pkg/")
  end
end

desc 'Install the gem locally'
task :install => :gem do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gemspec.file_name}}
  end
end

require 'rake/testtask'
desc "Test everything."
Rake::TestTask.new(:test) do |t|
  t.libs << './lib'
  t.pattern = 'test/test-*.rb'
  t.verbose = true
end
task :test => :lib

desc "same as test"
task :check => :test

require 'rbconfig'
def RbConfig.ruby
  File.join(RbConfig::CONFIG['bindir'],
            RbConfig::CONFIG['RUBY_INSTALL_NAME'] +
            RbConfig::CONFIG['EXEEXT'])
end unless defined? RbConfig.ruby

def run_standalone_ruby_files(list, opts={})
  puts '*' * 40
  list.each do |ruby_file|
    system(RbConfig.ruby, ruby_file)
    p $?.exitstatus
    break if $?.exitstatus != 0 && !opts[:continue]
  end
end

def run_standalone_ruby_file(directory, opts={})
  puts(('*' * 10) + ' ' + directory + ' ' + ('*' * 10))
  Dir.chdir(directory) do
    Dir.glob('*.rb').each do |ruby_file|
      puts(('-' * 20) + ' ' + ruby_file + ' ' + ('-' * 20))
      system(RbConfig.ruby, ruby_file)
      break if $?.exitstatus != 0 && !opts[:continue]
    end
  end
end

desc 'Create a GNU-style ChangeLog via git2cl'
task :ChangeLog do
  system('git log --pretty --numstat --summary | git2cl > ChangeLog')
end

desc 'Test units - the smaller tests'
Rake::TestTask.new(:'test') do |t|
  t.test_files = FileList['test/test-*.rb']
  # t.pattern = 'test/**/*test-*.rb' # instead of above
  t.options = '--verbose' if $VERBOSE
end

desc "Default action is same as 'test'."
task :default => :test

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc 'Validate the gemspec'
task :gemspec do
  gemspec.validate
end

# ---------  RDoc Documentation ------
require 'rdoc/task'
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "rbx-linecache #{LineCache::VERSION} Documentation"
  rdoc.rdoc_files.include(%w(lib/*.rb))
end

desc 'Same as rdoc'
task :doc => :rdoc

task :clobber_package do
  FileUtils.rm_rf File.join(ROOT_DIR, 'pkg'), :verbose => true
end

task :clobber_rdoc do
  FileUtils.rm_rf File.join(ROOT_DIR, 'doc'), :verbose => true
end

desc 'Remove residue from running patch'
task :rm_patch_residue do
  FileUtils.rm_rf Dir.glob('**/*.{rej,orig}'), :verbose => true
end

desc 'Remove ~ backup files'
task :rm_tilde_backups do
  FileUtils.rm_rf Dir.glob('**/*~'), :verbose => true
end

desc 'Remove built files'
task :clean => [:clobber_package, :clobber_rdoc, :rm_patch_residue,
                :rm_tilde_backups]
