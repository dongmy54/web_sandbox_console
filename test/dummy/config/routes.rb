Rails.application.routes.draw do
  mount WebSandboxConsole::Engine => "/web_sandbox_console"
end
