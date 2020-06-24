WebSandboxConsole::Engine.routes.draw do
  root "home#index"

  post :eval_code, to: "home#eval_code"
  get :view_file, to: "home#view_file"
  post :do_view_file, to: "home#do_view_file"

  # 授权相关
  get :fetch_token, to: "authorization#fetch_token"
  get :auth_page, to: "authorization#auth_page"
  post :auth, to: "authorization#auth"
end

