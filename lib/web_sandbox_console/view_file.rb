module WebSandboxConsole
  class ViewFile
    attr_accessor :file_or_dir         # 文件或目录
    attr_accessor :start_line_num      # 起始行数
    attr_accessor :end_line_num        # 结束行数
    attr_accessor :sed_start_time      # 开始时间
    attr_accessor :sed_end_time        # 结束时间
    attr_accessor :grep_content        # 过滤内容
    attr_accessor :touch_grep_protect  # 是否触发过滤保护
    attr_accessor :content_is_trimed   # 内容是否有裁剪

    def initialize(opts = {})
      @file_or_dir     = opts[:file_or_dir]
      @start_line_num  = (opts[:start_line_num].presence || 1).to_i
      @end_line_num    = (opts[:end_line_num].presence || 100).to_i
      @sed_start_time  = opts[:sed_start_time]
      @sed_end_time    = opts[:sed_end_time]
      @grep_content    = opts[:grep_content]
      @touch_grep_protect = false
      @content_is_trimed  = false
    end

    def view
      begin
        check_param
        file_or_dir_exists
        check_blacklist
        check_only_view_log
        view_file
      rescue ViewFileError => e
        {lines: [e.message]}
      end
    end

    # 检查参数
    def check_param
      raise ViewFileError, '文件或目录参数不能为空' if file_or_dir.blank?
      raise ViewFileError, "过滤内容中不能出现单引号" if grep_content.to_s.include?("'")
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

    # 检查 仅能查看日志
    def check_only_view_log
      if WebSandboxConsole.only_view_log_file
        raise ViewFileError, '仅可查看日志目录/文件' unless file_or_dir.split("/")[0] == 'log'
      end
    end

    # 目录下文件
    def files_in_dir
      lines = Dir["#{file_or_dir_path}/*"].map do |path|
        path += is_directory?(path) ? '(目录)' : '(文件）'
        path[file_or_dir_path.length..-1]
      end
      {lines: lines}
    end

    # 是否为大文件
    def is_big_file?
      File.new(file_or_dir_path).size > 10.megabytes
    end

    # 是否需要过滤
    def need_grep?
      @sed_start_time || @grep_content.present?
    end

    # 查看文件/目录
    def view_file
      if is_directory?(file_or_dir_path)
        files_in_dir
      else # 文件
        parse_start_and_end_time
        lines = if need_grep?
          grep_file_content
        elsif is_big_file?
          tail_any_line(1000)
        else
          special_line_content
        end
        # 修剪行数
        lines = content_trim(lines)

        {
          lines: add_line_num(lines), 
          total_line_num: cal_file_total_line_num,
          touch_grep_protect: @touch_grep_protect,
          content_is_trimed: @content_is_trimed
        }
      end
    end

    # 计算文件总行数
    def cal_file_total_line_num
      `wc -l < #{file_or_dir_path}`.to_i
    end

    # 最后 xx 行
    def tail_any_line(num)
      tail_any_line_content(num).split("\n")
    end

    # 最后多少行内容
    def tail_any_line_content(num)
      `tail -n #{num} #{file_or_dir_path}`
    end

    # 按指定行返回
    def special_line_content
      File.readlines(file_or_dir_path)[(start_line_num - 1)..(end_line_num - 1)]
    end
    
    # 过滤超时保护 
    def grep_timeout_protect
      begin
        Timeout::timeout(8) {yield}
      rescue Timeout::Error => e
        # 触发过滤保护
        @touch_grep_protect = true
        tail_any_line_content(1000)
      end
    end

    # 过滤文件
    def grep_file_content
      content = if @sed_start_time && @grep_content.present?
        grep_timeout_protect {`sed -n '/#{@sed_start_time}/,/#{@sed_end_time}/p' #{file_or_dir_path} | fgrep '#{@grep_content}'`}
      elsif @sed_start_time
        grep_timeout_protect {`sed -n '/#{@sed_start_time}/,/#{@sed_end_time}/p' #{file_or_dir_path}`}
      else
        grep_timeout_protect {`fgrep '#{@grep_content}' #{file_or_dir_path}`}
      end
      content.split("\n")
    end
    
    # 修剪过滤内容
    def content_trim(lines)
      if lines.length > 1000
        @content_is_trimed = true
        # 内容太多时 只返回前1000行
        lines.first(1000)
      else
        lines
      end
    end

    # 添加行号
    def add_line_num(lines)
      start_num = is_big_file? ? 1 : start_line_num
      lines.each_with_index.map do |line, index| 
        line = "#{index + start_num}:  #{line}"
        hightlight_grep_content(line)
      end
    end

    # 高亮内容
    def hightlight_grep_content(content)
      if @grep_content.present?
        content.gsub(@grep_content.to_s, "<span style='color: #E35520;'> #{@grep_content}</span>").html_safe
      else
        content
      end
    end

    private
      # 解析时间
      def parse_start_and_end_time
        formatter = datetime_formatter
        @sed_start_time = DateTime.parse(@sed_start_time).strftime(formatter) rescue nil
        @sed_end_time   = DateTime.parse(@sed_end_time).strftime(formatter) rescue nil
      end

      # 日志时间格式是否为标准格式
      def logger_datetime_is_default_formatter
        # 抽取日志的第二行
        logger_line   = `head -n 2 #{file_or_dir_path} | tail -n 1`
        datatime_part = logger_line.split(/DEBUG:|INFO:|WARN:|ERROR:|FATAL:|UNKNOWN:/).first.to_s
        datatime_part.include?("T")
      end
      
      # 解析日期格式
      def datetime_formatter
        logger_datetime_is_default_formatter ? "%FT%T" : "%F %T"
      end


  end
end
