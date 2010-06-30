$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'rubygems'
require 'rake/gempackagetask'

require 's3_shuttle'

spec = Gem::Specification.new do |s|
	s.platform			= Gem::Platform::RUBY
	s.name					= "S3Shuttle"
	s.version				= S3Shuttle::VERSION::STRING
	s.author				= "Jamie White"
	s.email					= "jamie@frankiandjonny.com"
	s.homepage			= "http://frankiandjonny.com"
	s.summary				= "Simple Amazon S3 upload queue DRb server"
	s.files					= ["CHANGELOG", "Rakefile", "README"] + FileList["{bin,examples,lib,test}/**/*"].to_a
	s.require_path	= "lib"
	s.executables		= ["s3_shuttle_start", "s3_shuttle_stop", "s3_shuttle_status"]
	s.autorequire		= "s3_shuttle"
	
	s.add_dependency("aws-s3", ">= 0.5.0")
end

Rake::GemPackageTask.new(spec) do |pkg|
	pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
	puts "generated latest version"
end
