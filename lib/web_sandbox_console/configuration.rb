module WebSandboxConsole
  # ip 白名单
  mattr_accessor :ip_whitelist
  # 基本认证
  mattr_accessor :http_basic_auth
  # 常量 黑名单 数组
  mattr_accessor :constant_blacklist
  # 类方法 黑名单 hash
  mattr_accessor :class_method_blacklist
  # 实例方法 黑名单 hash
  mattr_accessor :instance_method_blacklist
  # 日志路径
  mattr_accessor :console_log_path

  # 默认设置
  @@http_basic_auth = {name: 'dmy', password: '123456'}

  # 内置 实例方法 黑名单
  INSTANT_METOD_BUILT_IN_BLACKLIST = {
    Kernel: %i(system exec `),
    File: %i(chmod chown)
  }.freeze

  # 内置 类方法 黑名单
  CLASS_METHOD_BUILT_IN_BLACKLIST = {
    Kernel: %i(system exec `),
    File: %i(chmod chown new open delete read write),
    Dir: %i(new delete mkdir)
  }.freeze

  
  def self.setup
    yield self
  end

end