# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'
require 'rubygems' unless 
  Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/lib/linecache" unless 
  Object.const_defined?(:LineCache)

FILES = FileList[
  'AUTHORS',
  'COPYING',
  'ChangeLog',
  'NEWS',
  'README',
  'Rakefile',
  'lib/*.rb',
  'test/*.rb',
  'test/data/*.rb',
  'test/short-file'
]                        


Gem::Specification.new do |spec|
  spec.authors      = ['R. Bernstein']
  spec.date         = Time.now
  spec.description  = <<-EOF
LineCache is a module for reading and caching lines. This may be useful for
example in a debugger where the same lines are shown many times.

This version works only with a patched version of Ruby 1.9.2 and rb-threadframe.
EOF
  spec.add_dependency('rb-threadframe', '>= 0.32')
  spec.email        = 'rockyb@rubyforge.net'
  spec.files        = FILES.to_a  
  spec.has_rdoc     = true
  spec.homepage     = "http://rubyforge.org/projects/rocky-hacks/linecache"
  spec.name         = "linecache-tf"
  spec.license      = 'GPL2'
  spec.platform     = Gem::Platform::RUBY
  spec.require_path = 'lib'
  spec.required_ruby_version = '~> 1.9.2'
  spec.rubyforge_project = 'rocky-hacks'
  spec.summary      = 'Module to read and cache Ruby program files and file information'
  spec.version      = LineCache::VERSION
  spec.extra_rdoc_files = %w(README lib/linecache.rb lib/tracelines.rb)

  # Make the readme file the start page for the generated html
  spec.rdoc_options += %w(--main README)
  spec.rdoc_options += ['--title', "LineCache #{LineCache::VERSION} Documentation"]

end
