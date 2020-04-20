module WebSandboxConsole
  # 日志路径
  mattr_accessor :console_log_path

  def self.setup
    yield self
  end

end