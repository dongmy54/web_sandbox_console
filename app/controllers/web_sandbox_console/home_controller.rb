require_dependency "web_sandbox_console/application_controller"

module WebSandboxConsole
  class HomeController < ApplicationController
    before_action :restrict_ip
    http_basic_authenticate_with name: WebSandboxConsole.http_basic_auth[:name], password: WebSandboxConsole.http_basic_auth[:password] if WebSandboxConsole.http_basic_auth.present?

    def index
    end

    # 执行代码
    def eval_code
      @results = Sandbox.new(params[:code], session[:pass_auth]).evalotor
    end

    def view_file
    end

    # 查看文件
    def do_view_file
      @results = ViewFile.new(params).view
    end
  end
end
