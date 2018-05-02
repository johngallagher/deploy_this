class Shell
  def self.execute(command)
    %x{#{command}}
  end

  def self.success?(command)
    system(command)
  end

  def self.popen(command, &block)
    IO.popen(command) { block.yield }
  end
end

module Toolbelt
  class Deploy
    def initialize environment, server_name: Rails.root.basename.to_s, shell: Shell, stdout: STDOUT
      @environment = environment
      @server_name = server_name
      @shell = shell
      @stdout = stdout
    end

    def call
      if cloud_66_toolbelt_installed?
        @stdout.puts "Pushing #{current_branch}..."
        push_branch
        @stdout.puts ''

        @stdout.puts 'Redeploying app...'
        redeploy
      else
        @stdout.puts 'Cloud 66 toolbelt not found.'
        @stdout.puts ''
        @stdout.puts 'Install with:'
        @stdout.puts 'brew install cloud66/tap/c66cx'
        @stdout.puts ''
      end
    end

    def current_branch
      @current_branch ||= @shell.execute("echo $(git rev-parse --abbrev-ref HEAD)").chomp
    end

    def cloud_66_toolbelt_installed?
      @shell.success?("command -v cx > /dev/null")
    end

    def stack_and_environment_switches
      "--stack=#{@server_name} --environment=#{@environment}"
    end

    def current_branch_on_server
      @shell.execute("cx settings list #{stack_and_environment_switches} git.branch").chomp.split(' ').select(&:present?).second
    end

    def change_deploy_branch branch
      @shell.execute("cx settings set git.branch #{branch} #{stack_and_environment_switches}")
    end

    def push_branch
      @shell.execute("git push --set-upstream origin #{current_branch}")
    end

    def redeploy
      @shell.popen("cx redeploy --git-ref=#{current_branch} #{stack_and_environment_switches} --listen") do |io|
        return if io.nil?
        while (line = io.gets)
          @stdout.puts line
        end
      end
    end
  end
end
