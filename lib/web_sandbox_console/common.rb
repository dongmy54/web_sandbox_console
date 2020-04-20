module WebSandboxConsole
  module Common
    # uuid 方便取出日志
    def log_p(msg_or_exce, uuid = nil)
      @logger ||= Logger.new(log_path)

      if msg_or_exce.respond_to?(:message)
        @logger.info "#{uuid}:" + msg_or_exce.message 
        @logger.info "#{uuid}:" + msg_or_exce.backtrace.join("|||")
      else
        @logger.info "#{uuid}:" + msg_or_exce.inspect
      end
    end

    def log_path
      "#{Rails.root}/#{self.console_log_path || "log/web_sandbox_console.log"}"
    end
  end
end