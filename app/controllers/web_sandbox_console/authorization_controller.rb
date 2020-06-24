require_dependency "web_sandbox_console/application_controller"

module WebSandboxConsole
  class AuthorizationController < ApplicationController
    before_action :restrict_ip
    http_basic_authenticate_with name: WebSandboxConsole.http_basic_auth[:name], password: WebSandboxConsole.http_basic_auth[:password] if WebSandboxConsole.http_basic_auth.present?
    before_action :restrict_fetch_token_times, only: :fetch_token

    # 获取令牌
    def fetch_token
      @token = SecureRandom.uuid
      save_cache_token(@token)
    end

    # 授权
    def auth
      if params[:secret_text].blank?
        flash[:notice] = '密文为空'
        return redirect_to root_path
      end

      if public_key.blank?
        flash[:notice] = '公钥未配置'
        return redirect_to root_path
      end

      result_hash = decrypt_secret_text(params[:secret_text])
      token       = result_hash[:content]
      if result_hash[:success] && fetch_cache_token(token)
        flash[:notice] = "授权成功"
        session[:pass_auth] = true
      else
        flash[:notice] = "授权失败：#{result_hash[:content]}"
      end

      redirect_to root_path
    end

    private
      # 限制获取token次数 一天内不允许超过20次
      def restrict_fetch_token_times
        cache = Rails.cache
        times = cache.fetch('fetch_token_times', expires_in: 1.day) {0}
        
        if times > 20
          flash[:notice] = '一天内获取令牌不允许超过20次'
          rediect_to root_path
        end
        cache.write('fetch_token_times', times + 1)
      end

      # 保存token 到缓存
      def save_cache_token(key, value = nil)
        Rails.cache.write(key.to_s, value.presence || key.to_s, expires_in: 5.minutes)
      end

      # 获取 缓存中 token
      def fetch_cache_token(key)
        Rails.cache.read(key.to_s)
      end

      # 公钥
      def public_key
        WebSandboxConsole.public_key
      end

      # 解密
      def decrypt_secret_text(secret_text)
        begin
          base_text = Base64.decode64(secret_text)
          p_key = OpenSSL::PKey::RSA.new public_key
          text = p_key.public_decrypt(base_text)
          {success: true, content: text}
        rescue OpenSSL::PKey::RSAError
          {success: false, content: "密钥匹配失败"}
        rescue Exception => e
          {success: false, content: "发生未知错误: #{e.inspect};#{e.backtrace[0..2].join('\r\n')}"}
        end
      end

  end
end
