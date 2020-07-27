module WebSandboxConsole
  class Sandbox
    attr_accessor :code           # 代码
    attr_accessor :uuid           # 唯一标识
    attr_accessor :pass_auth      # 是否通过授权
    attr_accessor :exe_tmp_file   # 执行临时文件（由code 组成的运行代码）

    def initialize(code = nil, pass_auth = false)
      @code         = code
      @uuid         = SecureRandom.uuid
      @pass_auth    = pass_auth.presence || false
      @exe_tmp_file = "#{Rails.root}/tmp/sandbox/#{uuid}.rb"
    end

    # 同步执行
    def evalotor
      evalotor_block do
        exec_rails_runner
        get_result
      end
    end

    # 异步后台执行
    def asyn_evalotor
      evalotor_block do
        Thread.new {exec_rails_runner}
        ["已在后台执行，请耐心等待😊"]
      end
    end
    
    # 执行结构块
    def evalotor_block
      begin
        check_syntax
        write_exe_tmp_file
        yield
      rescue SandboxError => e
        [e.message]
      rescue Exception => e
        ["发生未知错误: #{e.inspect};#{e.backtrace[0..2].join('\r\n')}"]
      end
    end

    def runner_code
      str =<<-CODE
        result = nil
        begin
          WebSandboxConsole.current_uuid("#{self.uuid}")
          WebSandboxConsole.init_safe_env
          WebSandboxConsole.logger_sql
          #{self.pass_auth ? no_rollback_code : rollback_code}
        rescue Exception => e
          WebSandboxConsole.log_p(e)
        rescue SyntaxError => e
          WebSandboxConsole.log_p(e)
        end
        WebSandboxConsole.log_p(result)
      CODE
    end

    # 回滚code
    def rollback_code
      <<-EOF
        ActiveRecord::Base.transaction(requires_new: true) do
          result = eval(#{self.code.inspect})
          raise ActiveRecord::Rollback
        end
      EOF
    end

    # 不回滚code
    def no_rollback_code
      <<-EOF
        result = eval(#{self.code.inspect})
      EOF
    end
    
    # 临时文件目录
    def tmp_file_dir
      File.dirname(self.exe_tmp_file)
    end

    # 添加临时文件目录
    def add_tmp_file_dir
      FileUtils.mkdir_p(tmp_file_dir)  unless File.directory?(tmp_file_dir)
    end

    # 临时文件 需要清理？
    def tmp_file_need_clean?
      Dir["#{tmp_file_dir}/*"].count > 6
    end

    # 自动删除临时文件
    def auto_clean_tmp_file
      FileUtils.rm_rf(Dir["#{tmp_file_dir}/*"]) if tmp_file_need_clean?
    end

    # 写入 执行临时文件
    def write_exe_tmp_file
      add_tmp_file_dir
      auto_clean_tmp_file
      File.open(self.exe_tmp_file, 'w'){|f| f << runner_code}
    end

    # 准备检查语法
    def prepare_check_syntax
      add_tmp_file_dir
      File.open(self.exe_tmp_file, 'w'){|f| f << self.code}
    end

    # 检查 语法
    def check_syntax
      prepare_check_syntax
      unless `ruby -c #{self.exe_tmp_file}`.include?('Syntax OK')
        raise SandboxError, "存在语法错误"
      end
    end

    # 运行rails runner
    def exec_rails_runner
      @stdout = `RAILS_ENV=#{Rails.env} bundle exec rails runner #{self.exe_tmp_file}`
    end

    # 返回结果
    def return_result_arr
      last_10_lines = `tail -n 100 #{WebSandboxConsole.log_path} | grep #{self.uuid}`
      
      last_10_lines.split("\n").map do |line|
        line.split("#{self.uuid}:").last.split("|||")
      end.flatten
    end

    # 最终结果
    def get_result
      if @stdout.present?
        stdout_arr = ['------------ 打印值 ----------']
        stdout_arr.concat(@stdout.to_s.split("\n"))
        stdout_arr << '------------ 返回值 ----------'
        stdout_arr.concat(return_result_arr)
      else
        return_result_arr
      end
    end

  end
end