module WebSandboxConsole
  class ViewFile
    attr_accessor :file_or_dir     # 文件或目录
    attr_accessor :start_line_num  # 起始行数
    attr_accessor :end_line_num     # 结束行数

    def initialize(opts = {})
      @file_or_dir     = opts[:file_or_dir]
      @start_line_num  = opts[:start_line_num].present? ? opts[:start_line_num].to_i : 1
      @end_line_num    = opts[:end_line_num].present? ? opts[:end_line_num].to_i : 100
    end

    def view
      begin
        check_param
        file_or_dir_exists
        view_file
      rescue ViewFileError => e
        [e.message]
      end
    end

    # 检查参数
    def check_param
      raise ViewFileError, '文件或目录参数不能为空' if file_or_dir.blank?
    end

    # 绝对路径
    def file_or_dir_path
      "#{Rails.root}/#{file_or_dir}"
    end

    # 是否存在
    def file_or_dir_exists
      raise ViewFileError, '文件或目录不存在' unless File.exists?(file_or_dir_path)
    end

    # 是目录？
    def is_directory?(path)
      File.directory?(path)
    end

    # 目录下文件
    def files_in_dir
      Dir["#{file_or_dir_path}/*"].map do |path|
        path += is_directory?(path) ? '(目录)' : '(文件）'
        path[file_or_dir_path.length..-1]
      end
    end

    # 是否为大文件
    def is_big_file?
      File.new(file_or_dir_path).size > 10.megabytes
    end

    # 查看文件/目录
    def view_file
      if is_directory?(file_or_dir_path)
        files_in_dir
      else
        lines = is_big_file? ? tail_200_line : special_line_content
        add_line_num(lines)
      end
    end

    # 最后 200 行内容
    def tail_200_line
      (`tail -n 200 #{file_or_dir_path}`).split(/[\r,\r\n]/)
    end

    # 按指定行返回
    def special_line_content
      File.readlines(file_or_dir_path)[start_line_num..end_line_num]
    end

    # 添加行号
    def add_line_num(lines)
      start_num = is_big_file? ? 1 : start_line_num
      lines.each_with_index.map{|line, index| "#{index + start_num}:  #{line}"}
    end

  end
end
