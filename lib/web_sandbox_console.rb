require 'fileutils'
require "web_sandbox_console/engine"
require "web_sandbox_console/sandbox_error"
require "web_sandbox_console/configuration"
require "web_sandbox_console/common.rb"
require "web_sandbox_console/safe_ruby"
require "web_sandbox_console/sandbox"


module WebSandboxConsole
  extend Common
  extend SafeRuby

  # 初始化默认路由
  Engine.initializer 'rails_web_sandbox_console.mount_default' do
    Rails.application.routes.prepend do
      mount WebSandboxConsole::Engine => WebSandboxConsole.mount_engine_route_path
    end
  end
end
