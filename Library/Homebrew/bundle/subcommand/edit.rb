# typed: strict
# frozen_string_literal: true

require "abstract_subcommand"

module Homebrew
  module Cmd
    class Bundle < Homebrew::AbstractCommand
      class EditSubcommand < Homebrew::AbstractSubcommand
        subcommand_args do
          usage_banner <<~EOS
            `brew bundle edit`:
            Edit the `Brewfile` in your editor.
          EOS
          named_args :none
          switch "--install",
                 description: "Run `install` before continuing to other operations, e.g. `exec`."
        end

        sig { override.void }
        def run
          require "bundle/brewfile"

          exec_editor(Homebrew::Bundle::Brewfile.path(global: context.global, file: context.file))
        end
      end
    end
  end
end
