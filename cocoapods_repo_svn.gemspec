# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_repo_svn'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-repo-svn'
  spec.version       = CocoapodsRepoSvn::VERSION
  spec.authors       = ['Dustin Clark']
  spec.email         = ['dusty@isperldead.net']
  spec.description   = %q{CocoaPod plugin to add subversion support for spec repositories}
  spec.summary       = %q{Subversion support for spec repository}
  spec.homepage      = 'https://github.com/clarkda/cocoapods-repo-svn'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
