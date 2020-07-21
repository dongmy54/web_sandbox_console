module WebSandboxConsole
  module Common
    
    # logger sql语句
    def logger_sql(uuid = nil)
      logger = fetch_logger
      logger.level = :debug
      logger.formatter = proc {|severity, time, progname, msg|  "#{uuid}: #{msg}\n"}
      ActiveRecord::Base.logger = logger
    end

    # uuid 方便取出日志
    def log_p(msg_or_exce, uuid = nil)
      logger = fetch_logger

      if msg_or_exce.respond_to?(:message)
        logger.info "#{uuid}:" + msg_or_exce.message 
        logger.info "#{uuid}:" + msg_or_exce.backtrace.join("|||")
      else
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