# WebSandboxConsole
工作中许多时候，都需要我们连到服务器进入rails c下查询或一些数据。当运维人员时间比较充足的时候，情况还相对较好；如果一个运维人员，同时负责许多台服务器，让其帮忙负责查询就会浪费很大的一部分时间；为了解决这个问题，我想找到一种即安全、又方便的查询控制台，搜索了一些gem后，发现并没有符合我预期的gem,于是决定写一个相关功能的gem，旨在提供一个安全、方便的web 控制台.

这个控制台提供一个类似沙盒的安全环境，这里做的所有数据操作，都会回滚（不会真正写入数据库）；你可以配置 ip 白名单、基本认证，来增加访问安全性；另外在这个沙盒中，内置禁止了linux命令的执行,所以不用担心，ruby越界去做了linux的相关事情，当然还禁止了文件的新建、删除、目录的新建、删除等一系列方法；如果你需要更强的限制，你还可以去配置你想禁止使用的哪些方法等等，具体看配置文件。

## Usage
使用过程相当简单，和一般的gem，安装后你不用特殊去配置任何东西，就可以正常使用。所有的配置选项都是可选的。

## Installation
在 Gemfile 中添加:

```ruby
gem 'web_sandbox_console'
```

然后执行:
```bash
$ bundle
```

此时，如果是在本地，你访问 `http://localhost:3000/web_sandbox_console` 就能看到web控制台了。

## 配置
在bundle后 你就可以正常使用gem了，如果你需要配置的话，才用来看这步

在 rails 项目路径下,执行：
```bash
$ rails g web_sandbox_console
```

这会在项目路径下,创建如下文件（文件中已详细说明用法）
```ruby
# config/initializers/web_sandbox_console.rb

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

  # # 配置 日志路径 默认路径位于项目下
  # config.console_log_path = "log/web_sandbox_console.log"
end
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
