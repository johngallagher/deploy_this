require 'toolbelt/deploy'

describe Toolbelt::Deploy do
  describe '#call' do
    let(:environment) { "staging" }
    let(:server_name) { "server name" }
    let(:current_branch) { "some-branch" }

    subject { described_class.new(environment, server_name: server_name, shell: FakeShell, stdout: StringIO.new) }

    before { expect(FakeShell).to receive(:success?).with("command -v cx > /dev/null").and_return(cx_tool_installed) }

    context 'when cx tool is installed' do
      let(:cx_tool_installed) { true }

      it 'pushes the current branch and deploys it' do
        expect_shell_command("git push --set-upstream origin #{current_branch}")
        expect_shell_command("echo $(git rev-parse --abbrev-ref HEAD)", and_return: current_branch)
        expect_shell_command_streamed("cx redeploy --git-ref=#{current_branch} --stack=#{server_name} --environment=#{environment} --listen")

        subject.call
      end
    end
  end

  private

  def expect_shell_command(command, and_return: nil)
    expect(FakeShell).to receive(:execute).with(command).and_return(and_return)
  end

  def expect_shell_command_streamed(command)
    expect(FakeShell).to receive(:popen).with(command)
  end
end

class FakeShell
  def self.execute(command)
  end

  def self.success?(command)
  end

  def self.popen(command, &block)
  end
end

