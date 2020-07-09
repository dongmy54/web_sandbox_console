require_dependency "web_sandbox_console/application_controller"

module WebSandboxConsole
  class HomeController < ApplicationController
    
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
      results             = ViewFile.new(params).view
      @lines              = results[:lines]
      @total_line_num     = results[:total_line_num]
      @touch_grep_protect = results[:touch_grep_protect]
      @content_is_trimed  = results[:content_is_trimed]
    end

    # 下载文件页面
    def download_page
    end

    # 下载文件
    def download
      if params[:file_name].blank?
        flash[:notice] = "文件名不能为空"
        return redirect_to download_page_path
      end

      file_full_path = "#{Rails.root}/log/#{params[:file_name]}"
      unless File.exists?(file_full_path)
        flash[:notice] = '文件不存在，请检查文件名；或在其它服务器请多次尝试'
        return redirect_to download_page_path
      end

      # 打包
      `tar czf #{file_full_path}.tar.gz #{file_full_path}`
      # 如果是csv文件，需删除
      File.delete(file_full_path) if file_full_path.split(".").last == 'csv'

      send_file "#{file_full_path}.tar.gz"
    end

  end
end
