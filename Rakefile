#!/usr/bin/env rake
# Are we Rubinius? We'll test by checking the specific function we need.
raise RuntimeError, 
'This package is for Rubinius 1.2.[34] or 2.0.x only!' unless
  Object.constants.include?('Rubinius') && 
  Rubinius.constants.include?('VM') && 
  Rubinius::VERSION =~ /1\.2\.[34]/ || Rubinius::VERSION =~ /2\.0/

require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'rake/testtask'

ROOT_DIR = File.dirname(__FILE__)
Gemspec_filename = 'rbx-linecache.gemspec'
require File.join %W(#{ROOT_DIR} lib linecache)

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

desc "Build the gem"
task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build #{Gemspec_filename}"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv("#{gemspec.file_name}", "pkg/")

    # Now make a 2.0 package by changng 1.2 to 2.0 in the gemspec
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

task :default => [:test]

desc 'Install the gem locally'
task :install => :package do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gemspec.file_name}}
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
  t.options = '--verbose' if $VERBOSE
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
