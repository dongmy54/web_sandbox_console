module WebSandboxConsole
  module SafeRuby
    # 初始化安全环境
    def init_safe_env
      sanitize_constants
      sanitize_instance_methods
      sanitize_class_methods
      sanitize_logger_new
      sanitize_csv
      blacklist_method_remind
    end

    # 净化 类方法
    def sanitize_class_methods
      class_method_blacklists.each do |klass, methods|
        klass = Object.const_get(klass)
        methods.each do |method|
          next if klass.singleton_methods.exclude?(method)
          klass.singleton_class.send(:undef_method, method)
        end
      end
    end

    # 净化 实例方法
    def sanitize_instance_methods
      instance_method_blacklists.each do |klass, methods|
        klass = Object.const_get(klass)
        methods.each do |method|
          next if (klass != Kernel) && klass.instance_methods.exclude?(method)
          klass.send(:undef_method, method)
        end
      end
    end

    # 类方法黑名单列表
    def class_method_blacklists
      blacklist = if class_method_blacklist
        merge_method_hash(CLASS_METHOD_BUILT_IN_BLACKLIST, class_method_blacklist)
      else
        CLASS_METHOD_BUILT_IN_BLACKLIST
      end
    end

    # 实例方法黑名单列表
    def instance_method_blacklists
      blacklist = if instance_method_blacklist
        merge_method_hash(INSTANT_METOD_BUILT_IN_BLACKLIST,instance_method_blacklist)
      else
        INSTANT_METOD_BUILT_IN_BLACKLIST
      end
    end

    # 净化 常量
    def sanitize_constants
      return unless constant_blacklist
      constant_blacklist.each do |const|
        Object.send(:remove_const, const) if defined?(const)
      end
    end

    # 将两个hash 内部数组也同时合并，并去重
    def merge_method_hash(hash1, hash2)
      # 格式统一
      hash2.transform_keys!(&:to_sym).transform_keys!(&:to_sym).transform_values!{|i| i.map(&:to_sym)}
      # 共有的key 
      common_keys = hash2.keys & hash1.keys
      # hash2 特有keys
      hash2_special_keys = hash2.keys - hash1.keys
      # 特有keys 直接合到 hash1
      hash1.merge!(hash2.slice(*hash2_special_keys))
      # 共用keys 数组去重
      common_keys.each do |key|
        hash1[key] = (hash1[key] | hash2[key]).uniq
      end
      hash1
    end

    # 发现代码 中有 Logger.new(Rails.root.join('log', 'hubar')) 写法, 会 触发 File.open方法
    # 封装后避免调用 File.open(禁用)
    def sanitize_logger_new
      Logger.instance_eval do
        def new(logdev, shift_age = 0, shift_size = 1048576)
          instance = allocate
          instance.send(:initialize, logdev.to_s, shift_age, shift_size)
          instance
        end
      end
    end

    # 净化 csv
    def sanitize_csv
      require 'csv' unless defined? CSV

      CSV.instance_eval do
        # 重写方法 以写日志方式 写数据
        def open(filename, mode="r", **options)
          # 无论输入什么路径 都只会在log下创建文件
          basename = File.basename(filename, ".*")
          file_path = "#{Rails.root}/log/#{basename}.csv"
          logger = Logger.new(file_path)
          logger.formatter = proc {|severity, datetime, progname, msg| msg}

          logger.instance_exec do
            # 支持类型 csv 数据写入方式
            def << (data_arr)
              self.info data_arr.join(",") + "\n"
            end
          end

          yield(logger)
        end
      end
    end

    # 当拦截黑名单方法时提醒
    def blacklist_method_remind
      Kernel.class_exec do
        # 发现此处method_missing Array 没有flatten方法
        def flatten_arr(arr)
          new_arr = []
          arr.each do |e|
            if e.is_a?(Array)
              new_arr.concat(flatten_arr(e))
            else
              new_arr << e
            end
          end
          new_arr
        end

        def method_missing(name,*params)
          class_methods    = WebSandboxConsole.class_method_blacklists.values
          instance_methods = WebSandboxConsole.instance_method_blacklists.values
          
          if flatten_arr([class_methods, instance_methods]).include?(name.to_sym)
            puts "PS：当前代码执行过程中可能调用了黑名单方法，导致本次报错，请仔细检查..."
          end
          super
        end
      end
    end

  end
end