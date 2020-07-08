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

此时，如果是在本地，你访问 `http://localhost:3000/web_sandbox_console` 就能看到web控制台了,下面这个样子。
![Snip20200703_1.png](https://i.loli.net/2020/07/03/62JD5ErcPbAwHSn.png)

## 配置
```
在bundle后,就可以使用一些基础的功能了；
如果你不满足基础的功能、或者需要更高的安全性，很有必要仔细了解配置选项，总之还是很推荐对项目进行适当配置；
关于配置的详细介绍，在生成的文件中也有详细的说明，参照说明配置即可；
```

在 rails 项目路径下,执行：
```bash
$ rails g web_sandbox_console
```

这会在项目路径下,创建如下文件（即配置文件）
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
```

## 深入了解
主要包含三大功能块：代码执行、文件查看、日志下载，下面分别介绍

### 代码执行
1. 提交和异步执行

> 提交后代码会立即执行；如果点击异步执行，则代码会在后台异步执行，这对于需要执行非常耗时的代码，强烈建议异步执行；

2. 升级权限
![Snip20200703_1.png](https://i.loli.net/2020/07/03/26zf5WOBFqmaiHC.png)

```
通常你能做的操作就是，查查数据等，数据的所有操作都不会写入到数据库，这样很安全；但是每当你需要修改数据时，还是需要让运维处理；为了满足可以数据写入、和安全性的要求；开发了升级权限这个功能。

升级权限你需要在配置文件中配置公钥，自己保存私钥；整个过程采用非对称加密的方式，进行授权，还是比较安全的。
升级授权成功后，代码执行将不再回滚，会直接写入数据库。
```

升级权限流程如下：
> -  `config/initializers/web_sandbox_console.rb`配置公钥
> - 进入授权页面，点击获取令牌 `web_sandbox_console/auth_page`
> - 用私钥对令牌加密，然后用base64加密
> - 将加密的打印结果（注意是puts 文本）,输入加密密文框，提交

```ruby
# 本地生成 加密密文代码
require 'openssl'
require 'base64'

private_key = "你的私钥"
p_key = OpenSSL::PKey::RSA.new private_key
secret_text = p_key.private_encrypt("你的令牌")
encode_text = Base64.encode64(secret_text)
puts encode_text
```

### 文件查看
![Snip20200703_2.png](https://i.loli.net/2020/07/03/zFMjpRSX8fCDQ2i.png)
1. 目录和文件

> 你可以查看一个目录下有哪些文件夹或文件，你也可以直接查看文件的内容，默认返回一个文件的前100行

2. 指定行数
```
你可以根据文件总行数，指定查看文件的开始行数、结束行数。
PS: a. 在过滤文件（过滤内容/过滤时间）的时候，此时指定行数将被忽略
    b. 对于大文件（默认超过10M)，处于性能考虑，此时指定行数也会被忽略
```

3. 过滤
```
需要特别说明的是，过滤时间是针对日志文件写的，因此如果是非日志文件，将不会有任何效果。
建议：出于性能考虑，过滤时候尽量缩小时间范围
```

4. 权限

> 默认情况，只能查看日志文件或目录，当然你也可以去配置做调整。

### 日志下载
![Snip20200703_3.png](https://i.loli.net/2020/07/03/csW5OfEhPVeSbJz.png)
你可以直接输入文件名（需要带后缀）下载日志

### 关于数据导出
在gem 中你可用`CSV.open`的方式导出数据，出于安全考虑，这里open方法是复写之后的，内部没有调用`File.open`方法；

有一下几点需注意：
> 1. 你写入你任何路径，最终都只会在log目录下创建文件
> 2. 文件名以你路径中（/分隔）的最后一个名称

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
