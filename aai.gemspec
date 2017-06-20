# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aai/version'

Gem::Specification.new do |spec|
  spec.name          = "aai"
  spec.version       = Aai::VERSION
  spec.authors       = ["Ryan Moore"]
  spec.email         = ["moorer@udel.edu"]

  spec.summary       = %q{Seanie's amino acid similarity.}
  spec.description   = %q{Calculate Seanie's amino acid similarity score between multiple genomes/bins.}
  spec.homepage      = "https://github.com/mooreryan/aai.git"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "coveralls", "~> 0.8.21"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9.9"

  spec.add_runtime_dependency "abort_if", "~> 0.2.0"
  spec.add_runtime_dependency "parse_fasta", "~> 2.2"
  spec.add_runtime_dependency "systemu", "~> 2.6", ">= 2.6.5"
end