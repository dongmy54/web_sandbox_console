# web_sandbox_console 配置文件 
# 以下配置 都是可选的 缺少的情况下用默认值 或者 不生效
WebSandboxConsole.setup do |config|
  # 配置 引擎挂载位置
  # config.mount_engine_route_path = '/web_sandbox_console'

  # 配置 ip 白名单
  # config.ip_whitelist = %w(192.168.23.12 192.145.2.0/24)

  # # 配置 基本认证
  # config.http_basic_auth = {name: 'dmy', password: '123456'}

  # # 配置 黑名单 类方法
  # config.class_method_blacklist = {File: %i(delete read write),Dir: %i(new delete mkdir)}

  # # 配置 黑名单 实例方法
  # config.instance_method_blacklist = {Kernel: %i(system exec `),File: %i(chmod chown)}

  # 文件黑名单列表 （如果是目录 则目录下所有文件都不可用）目录以 / 结尾
  # 默认都是项目路径下的
  # config.view_file_blacklist = %w(config/secrets.yml vendor/)

  # 配置 文件权限，是否仅能查看log文件,默开启
  #config.only_view_log_file = false

  # 通过非对称加密方式 升级权限，授权通过后，可获得执行数据权限（PS: 数据操作不再回滚）
  # config.public_key = "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDMbJOE1vQT1jFpaH1GPYzdRJN/\nLh8VePmzXs5BYOLHB0xIjArL1NlXMbCJ+AS2rv3/oHIOdHhEuZw0tmm9DhG100R8\nRjBpsEKCDI88jl9qRkFmD3CVk8XQXv6c2IkRZCYSTvgDkmnKAlORksfw+p0cR2AQ\nlAtAsNsNviKYBzXKfQIDAQAB\n-----END PUBLIC KEY-----\n"

  # # 配置 日志路径 默认路径位于项目下
  # config.console_log_path = "log/web_sandbox_console.log"
end

