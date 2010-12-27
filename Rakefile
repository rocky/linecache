#!/usr/bin/env rake
# Are we Rubinius 1.1.1 or 1.2? 
raise RuntimeError, 'This package is for Rubinius only! (1.2, 1.2.1dev)' unless
  Object.constants.include?('Rubinius') && 
  Rubinius.constants.include?('VM') && 
  %w(1.2 1.2.1dev).member?(Rubinius::VERSION)

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

ROOT_DIR = File.dirname(__FILE__)
require File.join %W(#{ROOT_DIR} lib linecache)

def gemspec
  @gemspec ||= eval(File.read('.gemspec'), binding, '.gemspec')
end

desc "Build the gem"
task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build .gemspec"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv("#{gemspec.name}-#{gemspec.version}-universal-rubinius-1.2.gem", 
                 "pkg/#{gemspec.name}-#{gemspec.version}-universal-rubinius-1.2.gem")
  end
end

task :default => [:test]

desc 'Install the gem locally'
task :install => :package do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gemspec.name}-#{gemspec.version}}
  end
end    

desc "Create a GNU-style ChangeLog via svn2cl"
task :ChangeLog do
  system("svn2cl --authors=svn2cl_usermap")
end

desc 'Test units - the smaller tests'
Rake::TestTask.new(:'test') do |t|
  t.test_files = FileList['test/test-*.rb']
  # t.pattern = 'test/**/*test-*.rb' # instead of above
  t.verbose = true
end

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "rbx-linecache #{LineCache::VERSION} Documentation"
  rdoc.rdoc_files.include(%w(lib/*.rb))
end

desc "Same as rdoc"
task :doc => :rdoc

task :clobber_package do
  FileUtils.rm_rf File.join(ROOT_DIR, 'pkg')
end

task :clobber_rdoc do
  FileUtils.rm_rf File.join(ROOT_DIR, 'doc')
end

desc "Remove built files"
task :clean => [:clobber_package, :clobber_rdoc]
