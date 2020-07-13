$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "web_sandbox_console/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "web_sandbox_console"
  s.version     = WebSandboxConsole::VERSION
  s.authors     = ["dongmingyan"]
  s.email       = ["dongmingyan01@gmail.com"]
  s.homepage    = "https://github.com/dongmy54/web_sandbox_console"
  s.summary     = "A secure, convenient web console"
  s.description = "At work, many times, we need to connect to the server to enter the rails c query or some data. When the operator has plenty of time, the situation is relatively good; if an operator is responsible for many servers at the same time, it will waste a lot of time to help with the query; to solve this problem, I want to find a secure and convenient query console, after searching some gem, found and did not meet my expectations gem, so decided to write a related function of the console designed to provide a safe, convenient web."
  s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 0"
  s.add_dependency "jquery-rails"
end
