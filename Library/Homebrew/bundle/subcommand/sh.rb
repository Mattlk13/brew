# typed: strict
# frozen_string_literal: true

require "abstract_subcommand"

module Homebrew
  module Cmd
    class Bundle < Homebrew::AbstractCommand
      class ShSubcommand < Homebrew::AbstractSubcommand
        subcommand_args do
          usage_banner <<~EOS
            `brew bundle sh` [`--check`] [`--no-secrets`]:
            Run your shell in a `brew bundle exec` environment.
          EOS
          named_args :none
          switch "--install",
                 description: "Run `install` before continuing to other operations, e.g. `exec`."
          switch "--services",
                 description: "Temporarily start services while running the `exec` or `sh` command.",
                 env:         :bundle_services
          switch "--check",
                 description: "Check that all dependencies in the Brewfile are installed before " \
                              "running `exec`, `sh`, or `env`.",
                 env:         :bundle_check
          switch "--no-secrets",
                 description: "Attempt to remove secrets from the environment before `exec`, `sh`, or `env`.",
                 env:         :bundle_no_secrets
        end

        sig { override.void }
        def run
          ExecSubcommand.run_command("sh", args:, context:)
        end
      end
    end
  end
end
