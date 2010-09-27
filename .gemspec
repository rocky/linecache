# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'
require 'rubygems' unless 
  Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/lib/linecache" unless 
  Object.const_defined?(:LineCache)

FILES = FileList[
  # 'README.textile',
  'AUTHORS',
  'COPYING',
  'ChangeLog',
  'NEWS',
  'README',
  'Rakefile',
  'lib/*.rb',
  'test/*.rb',
  'test/data/*.rb',
  'test/short-file',
  'test/short-file2'                 
]                        


Gem::Specification.new do |spec|
  spec.add_dependency('rbx-require-relative')
  spec.authors      = ['R. Bernstein']
  spec.date         = Time.now
  spec.description = <<-EOF
LineCache is a module for reading and caching lines. This may be useful for
example in a debugger where the same lines are shown many times.
EOF
  ## spec.add_dependency('diff-lcs') # For testing only
  spec.email        = 'rockyb@rubyforge.net'
  spec.files        = FILES.to_a  
  spec.has_rdoc     = true
  spec.homepage     = 'http://wiki.github.com/rocky/rbx-trepanning'
  spec.name         = 'rbx-linecache'
  spec.license      = 'MIT'
  spec.platform     = Gem::Platform::RUBY
  spec.require_path = 'lib'
  spec.required_ruby_version = '~> 1.8.7'
  spec.rubyforge_project = 'rocky-hacks'
  spec.summary      = "Read file with caching"
  spec.version      = LineCache::VERSION

  # Make the readme file the start page for the generated html
  ## spec.rdoc_options += %w(--main README)
  spec.rdoc_options += ['--title', "LineCache #{LineCache::VERSION} Documentation"]
  spec.extra_rdoc_files = ['README', 'lib/linecache.rb', 'lib/tracelines.rb']
  spec.test_files = FileList['test/*.rb']
end
