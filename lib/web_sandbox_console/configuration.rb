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
  # 文件列表 黑名单
  mattr_accessor :view_file_blacklist
  # 仅能查看日志文件
  mattr_accessor :only_view_log_file
  # 日志路径
  mattr_accessor :console_log_path
  # 挂载 引擎路由位置
  mattr_accessor :mount_engine_route_path
  # 公钥
  mattr_accessor :public_key

  # 默认 引擎路由位置
  @@mount_engine_route_path = '/web_sandbox_console'
  # 默认 开启仅可查看日志
  @@only_view_log_file = true
 
  # 内置 实例方法 黑名单
  INSTANT_METOD_BUILT_IN_BLACKLIST = {
    Kernel: %i(system exec `),
    File: %i(chmod chown)
  }

  # 内置 类方法 黑名单
  CLASS_METHOD_BUILT_IN_BLACKLIST = {
    Kernel: %i(system exec `),
    File: %i(chmod chown new open delete read write),
    Dir: %i(new delete mkdir)
  }

  
  def self.setup
    yield self
    indifferent_access_deal(%w(http_basic_auth))
  end

  # 无差别hash 处理
  def self.indifferent_access_deal(mattr_arr)
    mattr_arr.each do |mattr|
      current_hash = send(mattr)
      next unless current_hash.is_a?(Hash)
      send("#{mattr}=", current_hash.with_indifferent_access)
    end
  end

end