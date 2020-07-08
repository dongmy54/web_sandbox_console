module WebSandboxConsole
  module SafeRuby
    # 初始化安全环境
    def init_safe_env
      sanitize_constants
      sanitize_instance_methods
      sanitize_class_methods
      sanitize_logger_new
      sanitize_csv
    end

    # 净化 类方法
    def sanitize_class_methods
      blacklist = if class_method_blacklist
        merge_method_hash(CLASS_METHOD_BUILT_IN_BLACKLIST, class_method_blacklist)
      else
        CLASS_METHOD_BUILT_IN_BLACKLIST
      end

      blacklist.each do |klass, methods|
        klass = Object.const_get(klass)
        methods.each do |method|
          next if klass.singleton_methods.exclude?(method)
          klass.singleton_class.send(:undef_method, method)
        end
      end
    end

    # 净化 实例方法
    def sanitize_instance_methods
      blacklist = if instance_method_blacklist
        merge_method_hash(INSTANT_METOD_BUILT_IN_BLACKLIST,instance_method_blacklist)
      else
        INSTANT_METOD_BUILT_IN_BLACKLIST
      end

      blacklist.each do |klass, methods|
        klass = Object.const_get(klass)
        methods.each do |method|
          next if (klass != Kernel) && klass.instance_methods.exclude?(method)
          klass.send(:undef_method, method)
        end
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

  end
end