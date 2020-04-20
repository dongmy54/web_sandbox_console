WebSandboxConsole::Engine.routes.draw do
  root "home#index"

  post :eval_code, to: "home#eval_code"
end
