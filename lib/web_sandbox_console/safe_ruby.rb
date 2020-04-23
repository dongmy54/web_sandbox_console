module WebSandboxConsole
  module SafeRuby
    # 初始化安全环境
    def init_safe_env
      sanitize_constants
      sanitize_instance_methods
      sanitize_class_methods
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
          next if klass.singleton_methods(false).exclude?(method)
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
          next if klass.instance_methods(false).exclude?(method)
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
      hash2.transform_keys!(&:to_sym).transform_values!{|val_arr| val_arr.map{|val| val.to_sym}}
      # 共有的key 
      common_keys = hash2.keys & hash1.keys
      # hash2 特有keys
      hash2_special_keys = hash2.keys - hash1.keys
      # 特有keys 直接合到 hash1
      hash1.merge!(hash2.slice(hash2_special_keys))
      # 共用keys 数组去重
      common_keys.each do |key|
        hash1[key] = (hash1[key] | hash2[key]).uniq
      end
      hash1
    end

  end
end