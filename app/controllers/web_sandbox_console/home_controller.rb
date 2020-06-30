require_dependency "web_sandbox_console/application_controller"

module WebSandboxConsole
  class HomeController < ApplicationController
    before_action :restrict_ip
    http_basic_authenticate_with name: WebSandboxConsole.http_basic_auth[:name], password: WebSandboxConsole.http_basic_auth[:password] if WebSandboxConsole.http_basic_auth.present?

    def index
    end

    # 执行代码
    def eval_code
      sandbox = Sandbox.new(params[:code], session[:pass_auth])

      @results = if params[:commit] == '异步执行'
        sandbox.asyn_evalotor
      else
        sandbox.evalotor
      end
    end

    def view_file
    end

    # 查看文件
    def do_view_file
      results         = ViewFile.new(params).view
      @lines          = results[:lines]
      @total_line_num = results[:total_line_num]
    end

    # 下载文件
    def download
      return render text: "文件名不能为空" if params[:file_name].blank?
      file_full_path = "#{Rails.root}/log/#{params[:file_name]}.#{request.url.split(".").last}"
      return render text: '文件不存在，可能在其它服务器请多次尝试，或检查文件名(需要带扩展比如：a.log)' unless File.exists?(file_full_path)
      send_file file_full_path
    end

  end
end
