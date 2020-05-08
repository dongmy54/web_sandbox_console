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
        check_blacklist
        view_file
      rescue ViewFileError => e
        [e.message]
      end
    end

    # 检查参数
    def check_param
      raise ViewFileError, '文件或目录参数不能为空' if file_or_dir.blank?
    end

    # 转换成项目路径
    def project_path(path)
      "#{Rails.root}/#{path}"
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

    # 目录下所有子文件 目录
    def dir_all_sub_file_or_dir(current_dir)
      Dir["#{current_dir}**/*"]
    end

    # 黑名单 包含自身 及其 子目录/文件
    def blacklist_all_file_dir_arr
      black_lists = WebSandboxConsole.view_file_blacklist
      return [] if black_lists.blank?

      result_arr = black_lists.inject([]) do |result_arr, black_item_path|
        current_path = project_path(black_item_path)

        if is_directory?(current_path)
          result_arr.concat(dir_all_sub_file_or_dir(current_path))
        else
          result_arr
        end
      end
      black_lists.map{|i| project_path(i)}.concat(result_arr)
    end
    
    # 检查是否为黑名单 文件 / 目录
    def check_blacklist
      black_lists = blacklist_all_file_dir_arr
      raise ViewFileError, '文件或目录无权限查看' if black_lists.include?(file_or_dir_path) || black_lists.include?(file_or_dir_path + '/')
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
      File.readlines(file_or_dir_path)[(start_line_num - 1)..(end_line_num - 1)]
    end

    # 添加行号
    def add_line_num(lines)
      start_num = is_big_file? ? 1 : start_line_num
      lines.each_with_index.map{|line, index| "#{index + start_num}:  #{line}"}
    end

  end
end
