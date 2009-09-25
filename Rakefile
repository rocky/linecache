#!/usr/bin/env rake
# -*- Ruby -*-
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# ------- Default Package ----------
PKG_VERSION = open(File.join(File.dirname(__FILE__), 'VERSION')) do 
  |f| f.readlines[0].chomp
end
PKG_NAME           = 'linecache'
PKG_FILE_NAME      = "#{PKG_NAME}-#{PKG_VERSION}"
RUBY_FORGE_PROJECT = 'rocky-hacks'
RUBY_FORGE_USER    = 'rockyb'

FILES = FileList[
  'AUTHORS',
  'COPYING',
  'ChangeLog',
  'NEWS',
  'README',
  'Rakefile',
  'VERSION',
  'lib/*.rb',
  'test/*.rb',
  'test/data/*.rb',
  'test/short-file'
]                        

desc "Test everything."
test_task = task :test => :lib do 
  Rake::TestTask.new(:test) do |t|
    t.pattern = 'test/test-*.rb'
    t.verbose = true
  end
end

desc "Test everything - same as test."
task :check => :test

desc "Create a GNU-style ChangeLog via svn2cl"
task :ChangeLog do
  system("svn2cl --authors=svn2cl_usermap")
end

# Base GEM Specification
default_spec = Gem::Specification.new do |spec|
  spec.name = "linecache"
  
  spec.homepage = "http://rubyforge.org/projects/rocky-hacks/linecache"
  spec.summary = "Read file with caching"
  spec.description = <<-EOF
LineCache is a module for reading and caching lines. This may be useful for
example in a debugger where the same lines are shown many times.
EOF

  spec.version = "1.9.#{PKG_VERSION}"

  spec.author = "R. Bernstein"
  spec.email = "rockyb@rubyforge.net"
  spec.platform = Gem::Platform::RUBY
  spec.require_path = "lib"
  spec.files = FILES.to_a  

  spec.required_ruby_version = '>= 1.9.1'
  spec.date = Time.now
  spec.add_dependency('rb-threadframe', '>= 0.2')
  spec.rubyforge_project = 'rocky-hacks'
  
  # rdoc
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w(README lib/linecache.rb lib/tracelines.rb)

  spec.test_files = FileList['test/*.rb']
end

# Rake task to build the default package
Rake::GemPackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
end

task :default => [:test]

# desc "Publish linecache to RubyForge."
# task :publish do 
#   require 'rake/contrib/sshpublisher'
  
#   # Get ruby-debug path.
#   ruby_debug_path = File.expand_path(File.dirname(__FILE__))

#   publisher = Rake::SshDirPublisher.new("rockyb@rubyforge.org",
#         "/var/www/gforge-projects/rocky-hacks/linecache", ruby_debug_path)
# end

desc "Remove built files"
task :clean => [:clobber_package, :clobber_rdoc]

# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "linecache"
  # Show source inline with line numbers
  rdoc.options << "--inline-source" << "--line-numbers"
  # Make the readme file the start page for the generated html
  rdoc.options << '--main' << 'README'
  rdoc.rdoc_files.include(%w(lib/*.rb README COPYING))
end

# desc "Publish the release files to RubyForge."
# task :rubyforge_upload do
#   `rubyforge login`
#   release_command = "rubyforge add_release #{PKG_NAME} #{PKG_NAME} '#{PKG_NAME}-#{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.gem"
#   puts release_command
#   system(release_command)
# end
