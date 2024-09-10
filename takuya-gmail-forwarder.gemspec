# frozen_string_literal: true


Gem::Specification.new do |spec|
  ##
  require_relative 'lib/takuya/gmail-forwarder'

  spec.name          = "takuya-gmail-forwarder"
  spec.version       = '0.1.0'
  spec.authors       = ["takuya"]
  spec.email         = ["55338+takuya@users.noreply.github.com"]
  spec.licenses      = ['GPL-3.0-or-later']
  spec.summary       = "smtp proxy server to gmail(smtp:xoauth2)"
  spec.description   = "gmail forwarder by using smtp.gmail.com :xoauth2"
  spec.homepage      = "https://github.com/takuya/ruby-gmail-forwarder/"
  ## metadata
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/takuya/ruby-gmail-forwarder"
  spec.metadata["changelog_uri"] = "https://github.com/takuya/ruby-gmail-forwarder/README.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  #spec.bindir        = "exe"
  #spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  # spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")
  # spec.add_dependency 'takuya-xoauth2'
  # spec.add_dependency 'dot-env'
  # spec.add_dependency 'midi-smtp-server'
  # spec.add_dependency 'mail'

end