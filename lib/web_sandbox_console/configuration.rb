module WebSandboxConsole
  # ip 白名单
  mattr_accessor :ip_whitelist
  # 常量 黑名单 数组
  mattr_accessor :constant_blacklist
  # 类方法 黑名单 hash
  mattr_accessor :class_method_blacklist
  # 实例方法 黑名单 hash
  mattr_accessor :instance_method_blacklist
  # 日志路径
  mattr_accessor :console_log_path

  def self.setup
    yield self
  end

end