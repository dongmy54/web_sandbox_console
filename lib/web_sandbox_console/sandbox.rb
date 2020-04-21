module WebSandboxConsole
  class Sandbox
    attr_accessor :code
    attr_accessor :uuid

    def initialize(code = nil)
      @code   = escape_single_quote_mark(code)
      @uuid   = SecureRandom.uuid
    end

    def evalotor
      `bundle exec rails runner '#{runner_code}'`
      get_result
    end

    def runner_code
      str =<<-CODE
        WebSandboxConsole.init_safe_env
        result = nil
        begin
          ActiveRecord::Base.transaction(requires_new: true) do
            result = (#{self.code})
            raise ActiveRecord::Rollback
          end
        rescue Exception => e
          WebSandboxConsole.log_p(e, "#{self.uuid}")
        end
        WebSandboxConsole.log_p(result, "#{self.uuid}")
      CODE
    end

    def get_result
      last_10_lines = `tail -n 10 #{WebSandboxConsole.log_path} | grep #{self.uuid}`
      
      last_10_lines.split("\n").map do |line|
        line.split("#{self.uuid}:").last.split("|||")
      end.flatten
    end

    # 转义单引号
    def escape_single_quote_mark(code)
      code.gsub(/'/,'"')
    end
  end
end