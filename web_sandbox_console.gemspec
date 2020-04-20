$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "web_sandbox_console/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "web_sandbox_console"
  s.version     = WebSandboxConsole::VERSION
  s.authors     = ["dongmingyan"]
  s.email       = ["dongmingyan01@gmail.com"]
  s.homepage    = ""
  s.summary     = ": Summary of WebSandboxConsole."
  s.description = ": Description of WebSandboxConsole."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 0"
end
