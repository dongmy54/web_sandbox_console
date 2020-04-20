module WebSandboxConsole
  class Sandbox
    attr_accessor :code
    attr_accessor :uuid

    def initialize(code = nil)
      @code   = code
      @uuid   = SecureRandom.uuid
    end

    def evalotor
      system("bundle exec rails runner '#{runner_code}'")
      get_result
    end

    def runner_code
      str =<<-CODE
        result = nil
        logger = Logger.new("#{Rails.root}/log/web_sandbox_console.log")
        begin
          ActiveRecord::Base.transaction(requires_new: true) do
            result = #{self.code}
            raise ActiveRecord::Rollback
          end
        rescue Exception => e
          logger.info "#{self.uuid}:" + e.message
        end
        logger.info "#{self.uuid}:" + result.inspect
      CODE
    end

    def get_result
      last_10_lines = `tail -n 10 "#{Rails.root}/log/web_sandbox_console.log" | grep #{self.uuid}`
      
      last_10_lines.split("\n").map do |line|
        line.split("#{self.uuid}:").last
      end.join("\r\n")
    end
  end
end