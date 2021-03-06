module WebSandboxConsole
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    
    before_action :restrict_ip
    http_basic_authenticate_with name: WebSandboxConsole.http_basic_auth[:name].to_s, password: WebSandboxConsole.http_basic_auth[:password].to_s if WebSandboxConsole.http_basic_auth.present?


    # 限制ip
    def restrict_ip
      return unless ip_whitelist = WebSandboxConsole.ip_whitelist
      
      request_ip = IPAddr.new(request.remote_ip)
      unless ip_whitelist.any? {|legal_ip| IPAddr.new(legal_ip).include?(request_ip)}
        render text: "非法请求"
      end
    end
  end
end
