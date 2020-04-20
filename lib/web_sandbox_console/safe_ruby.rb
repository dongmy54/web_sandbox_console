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
        CLASS_METHOD_BUILT_IN_BLACKLIST.merge(class_method_blacklist)
      else
        CLASS_METHOD_BUILT_IN_BLACKLIST
      end

      blacklist.each do |klass, methods|
        klass = Object.const_get(klass)
        methods.each do |method|
          klass.singleton_class.send(:undef_method, method)
        end
      end
    end

    # 净化 实例方法
    def sanitize_instance_methods
      blacklist = if instance_method_blacklist
        INSTANT_METOD_BUILT_IN_BLACKLIST.merge(instance_method_blacklist)
      else
        INSTANT_METOD_BUILT_IN_BLACKLIST
      end

      blacklist.each do |klass, methods|
        klass = Object.const_get(klass)
        methods.each do |method|
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

  end
end