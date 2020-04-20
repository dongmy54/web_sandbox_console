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
        begin
          ActiveRecord::Base.transaction(requires_new: true) do
            result = #{self.code}
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
  end
end