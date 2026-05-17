# typed: false
# frozen_string_literal: true

require "cmd/services"
require "cmd/shared_examples/args_parse"

RSpec.describe Homebrew::Cmd::Services, :needs_daemon_manager do
  it_behaves_like "parseable arguments"

  it "sets canonical subcommand names", :aggregate_failures do
    expect(described_class.new([]).args.subcommand).to eq("list")
    expect(described_class.new(%w[i testball]).args.subcommand).to eq("info")
  end

  it "rejects file-only options for info" do
    expect { described_class.new(%w[info testball --file=/tmp/service.plist]) }
      .to raise_error(UsageError, /`info` subcommand does not accept the `--file` flag/)
  end

  it "allows controlling services", :integration_test do
    expect { brew "services", "list" }
      .to not_to_output.to_stderr
      .and not_to_output.to_stdout
      .and be_a_success
  end
end
