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
  s.summary     = "一个安全、方便的web 控制台"
  s.description = "工作中许多时候，都需要我们连到服务器进入rails c下查询或一些数据。当运维人员时间比较充足的时候，情况还相对较好；如果一个运维人员，同时负责许多台服务器，让其帮忙负责查询就会浪费很大的一部分时间；为了解决这个问题，我想找到一种即安全、又方便的查询控制台，搜索了一些gem后，发现并没有符合我预期的gem,于是决定写一个相关功能的gem，旨在提供一个安全、方便的web 控制台."
  s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 0"
  s.add_dependency "jquery-rails"
end
