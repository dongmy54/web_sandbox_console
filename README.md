# WebSandboxConsole
工作中许多时候，都需要我们连到服务器进入rails c下查询或一些数据。当运维人员时间比较充足的时候，情况还相对较好；如果一个运维人员，同时负责许多台服务器，让其帮忙负责查询就会浪费很大的一部分时间；为了解决这个问题，我想找到一种即安全、又方便的查询控制台，搜索了一些gem后，发现并没有符合我预期的gem,于是决定写一个相关功能的gem，旨在提供一个安全、方便的web 控制台.

这个控制台提供一个类似沙盒的安全环境，这里做的所有数据操作，都会回滚（不会真正写入数据库）；你可以配置 ip 白名单、基本认证，来增加访问安全性；另外在这个沙盒中，内置禁止了linux命令的执行,所以不用担心，ruby越界去做了linux的相关事情，当然还禁止了文件的新建、删除、目录的新建、删除等一系列方法；如果你需要更强的限制，你还可以去配置你想禁止使用的哪些方法等等，具体看配置文件。

此gem基本涵盖了日常使用的常用功能，包括：数据查询、数据修改、数据导出、日志查看、日志时间或内容过滤、文件查看，日志下载等。

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

PS：代码输入框支持代码高亮，你可以像在代码编辑器一样自由编写代码
![Snip20200710_1.png](https://i.loli.net/2020/07/10/XqolSYAIJGKa5xg.png)

## 配置
在bundle后,就可以直接使用了，为了安全起见，建议进一步配置基本认证；如果需要数据修改权限，还需要配置公钥；关于配置选项的具体说明，请参阅配置文件注释。

在 rails 项目路径下,执行：
```bash
$ rails g web_sandbox_console
```

会在项目路径下,创建两个配置文件
一、config/initializers/web_sandbox_console.rb文件

```ruby
# config/initializers/web_sandbox_console.rb

require 'yaml'

config_file_path = "#{Rails.root}/config/web_sandbox_console.yml"
config_hash = File.exists?(config_file_path) ? YAML.load_file(config_file_path).with_indifferent_access[:web_sandbox_console] : {}

# web_sandbox_console 配置文件 
# 以下配置 都是可选的 缺少的情况下用默认值 或者 不生效
WebSandboxConsole.setup do |config|
  # 配置 引擎挂载位置
  # config.mount_engine_route_path = '/web_sandbox_console'

  # 配置 ip 白名单
  # config.ip_whitelist = %w(192.168.23.12 192.145.2.0/24)

  # 配置 基本认证 在 config/web_sandbox_console.yml中配置
  # PS: 1. 即使config/web_sandbox_console.yml文件不存在，也不会有任何使用上的影响,效果相当于没有开启
  #     2. 下面这行不用注释掉，只要不配置yml文件就行
  config.http_basic_auth = config_hash[:http_basic_auth]

  # # 配置 黑名单 类方法
  # config.class_method_blacklist = {File: %i(delete read write),Dir: %i(new delete mkdir)}

  # # 配置 黑名单 实例方法
  # config.instance_method_blacklist = {Kernel: %i(system exec `),File: %i(chmod chown)}

  # 文件黑名单列表 （如果是目录 则目录下所有文件都不可用）目录以 / 结尾
  # 默认都是项目路径下的
  # config.view_file_blacklist = %w(config/secrets.yml vendor/)

  # 配置 文件权限，是否仅能查看log文件,默认开启
  #config.only_view_log_file = false

  # 通过非对称加密方式 升级权限，授权通过后，可获得执行数据权限（PS: 数据操作不再回滚）
  # PS：配置同 http_basic_auth
  config.public_key = config_hash[:public_key]

  # # 配置 日志路径 默认路径位于项目下
  # config.console_log_path = "log/web_sandbox_console.log"
end
```

二、config/web_sandbox_console.yml.example 文件

主要用于配置基本授权、升级权限需要用到的公钥，参照example文件创建yml文件即可
```ruby
# config/web_sandbox_console.yml.example

web_sandbox_console:
  http_basic_auth:
    name: dmy
    password: 123456
  public_key: "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDMbJOE1vQT1jFpaH1GPYzdRJN/\nLh8VePmzXs5BYOLHB0xIjArL1NlXMbCJ+AS2rv3/oHIOdHhEuZw0tmm9DhG100R8\nRjBpsEKCDI88jl9qRkFmD3CVk8XQXv6c2IkRZCYSTvgDkmnKAlORksfw+p0cR2AQ\nlAtAsNsNviKYBzXKfQIDAQAB\n-----END PUBLIC KEY-----\n"

```

关于配置的补充说明：

> 建议不要轻易配置黑名单方法，因为禁用某些方法后，可能会导致许多意想不到问题；有可能不小心禁用到rails框架或gem使用的一些方法；
>
> 对于此gem内置禁用的方法，gem内部是做了一些兼容性的处理的，因此不会有什么问题

## 深入了解

主要包含三大功能块：代码执行、文件查看、日志下载，下面分别介绍

### 代码执行
1. 提交和异步执行

> 提交后代码会立即执行,及时返回执行结果
>
> 异步执行，代码会在后台异步执行，这对于执行时间非常长的代码，强烈建议异步执行；比如批量更新数据、导出数据等

2. 升级权限
  ![Snip20200703_1.png](https://i.loli.net/2020/07/03/26zf5WOBFqmaiHC.png)

> 大多数时候，可能用到的操作就是查数据，但是，有时你可能需要修改某条数据，那么功能就不够用了
>
> 为了支持数据的修改，同时保证安全性，加入了升级权限这个功能
>
> 整个过程相当简单，在yaml文件中配置好公钥 -> 获取token -> 本地加密后回传 -> 授权成功
>
> 授权成功后，所有数据操作将不再执行回滚（PS：未升级授权时，做的所有数据操作都会执行回滚，不会真正写入数据库）



升级权限流程如下：
> 1. config/web_sandbox_console.yml`中配置公钥
>
> 2. 进入授权页面，点击获取令牌 
>
> 3. 用私钥对令牌加密，然后用base64加密
>
> 4. 将加密的打印结果（注意是puts 文本）,输入加密密文框，提交

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

   > 你可以根据文件总行数，指定查看文件的开始行数、结束行数。
   > PS: a. 在过滤文件（过滤内容/过滤时间）的时候，此时指定行数将被忽略
   >     b. 对于大文件（默认超过10M)，处于性能考虑，此时指定行数也会被忽略
3. 过滤内容

   > 当过滤内容时，仅返回匹配的行，匹配行的上下文是不会返回的
   >
   > 因此如果需要查看匹配行的上下文，需要再次根据匹配行的时间做过滤（PS：此时需清掉内容输入框）

4. 过滤时间

   > 可以只填开始时间，不填结束时间，此时返回该时间的日志
4. 权限

   > 默认情况，只能查看日志文件或目录，当然你也可以去配置做调整。

5. 其它

   > 1. 可以根据返回内容的提示，了解当前查询（文件总行数、当前按照某种方式返回）
   > 2. 查询的逻辑如下：
   > 3. 如果只指定文件名，且文件比较小（小文件），默认返回文件前100行
   > 4. 如果只指定文件名，文件比较大（大文件），默认返回文件最后1000行
   > 5. 如果指定了文件名、过滤内容，则忽略行数查找，直接依据过滤内容匹配行，如果匹配到的行数超过1000行，则返回匹配出的前1000行
   > 6. 如果指定了文件名、过滤内容、过滤时间，则先按照时间匹配出内容，然后根据内容进行匹配

### 日志下载

![Snip20200703_3.png](https://i.loli.net/2020/07/03/csW5OfEhPVeSbJz.png)
你可以直接输入文件名（需要带后缀）下载日志

### 关于数据导出

可以先在代码执行页面，用`CSV.open`方式生成 csv文件，然后在日志下载中去下载创建的csv文件

有一下几点需注意：
> 1. 在`CSV.open`中写的任何路径，都不会生效，最终只会在log目录下创建csv文件；比如`CSV.open('#{Rails.root}/hu/bar.txt') 会在log目录下，生成bar.csv文件
> 3. csv 文件下载后，会自动删除掉，因此只能下载一次


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).