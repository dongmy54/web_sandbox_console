require 'test_helper'
require 'generators/web_sandbox_console/web_sandbox_console_generator'

module WebSandboxConsole
  class WebSandboxConsoleGeneratorTest < Rails::Generators::TestCase
    tests WebSandboxConsoleGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
