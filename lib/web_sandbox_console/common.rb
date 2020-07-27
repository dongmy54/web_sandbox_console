module WebSandboxConsole
  module Common
    
    def current_uuid(uuid=nil)
      @uuid ||= uuid
    end

    # logger sql语句
    def logger_sql
      logger = fetch_logger
      logger.level = 0
      logger.formatter = proc {|severity, time, progname, msg|  "#{current_uuid}: #{msg}\n"}
      ActiveRecord::Base.logger = logger
    end

    # uuid 方便取出日志
    def log_p(msg_or_exce, is_general_text = false)
      uuid   = current_uuid
      logger = fetch_logger
      
      if msg_or_exce.respond_to?(:message) # 异常
        logger.info "#{uuid}:" + msg_or_exce.message 
        logger.info "#{uuid}:" + msg_or_exce.backtrace.join("|||")
      elsif is_general_text  # 普通文本
        logger.info "#{uuid}:" + msg_or_exce.inspect
      else                   # 返回值
        logger.info "#{uuid}: => " + msg_or_exce.inspect
      end
    end

    # 获取 logger
    def fetch_logger
      @logger ||= Logger.new(log_path, 'daily')
    end

    def log_path
      "#{Rails.root}/#{self.console_log_path || "log/web_sandbox_console.log"}"
    end
  end
end