class WebSandboxConsoleGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  def copy_initializer_file
    # 源文件 目标位置
    copy_file "web_sandbox_console.rb", "config/initializers/web_sandbox_console.rb"
  end
end
