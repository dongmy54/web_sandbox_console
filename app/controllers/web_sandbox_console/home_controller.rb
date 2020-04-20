require_dependency "web_sandbox_console/application_controller"

module WebSandboxConsole
  class HomeController < ApplicationController
    def index
    end

    def eval_code
      @result = Sandbox.new(params[:code]).evalotor
    end
  end
end
