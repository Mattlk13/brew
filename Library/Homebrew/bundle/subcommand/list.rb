# typed: strict
# frozen_string_literal: true

require "abstract_subcommand"
require "bundle/extensions/extension"

require "bundle/brewfile"
require "bundle/lister"
module Homebrew
  module Cmd
    class Bundle < Homebrew::AbstractCommand
      class ListSubcommand < Homebrew::AbstractSubcommand
        subcommand_args do
          usage_banner <<~EOS
            `brew bundle list`:
            List all dependencies present in the `Brewfile`.

            By default, only Homebrew formula dependencies are listed.
          EOS
          named_args :none
          switch "--install",
                 description: "Run `install` before continuing to other operations, e.g. `exec`."
          switch "--all",
                 description: "`list` all dependencies."
          switch "--formula", "--formulae", "--brews",
                 description: "`list`, `dump` or `cleanup` Homebrew formula dependencies."
          switch "--cask", "--casks",
                 description: "`list`, `dump` or `cleanup` Homebrew cask dependencies."
          switch "--tap", "--taps",
                 description: "`list`, `dump` or `cleanup` Homebrew tap dependencies."
          Homebrew::Bundle.extensions.each do |extension|
            switch "--#{extension.flag}",
                   description: extension.switch_description
          end
        end

        sig { override.void }
        def run
          Homebrew::Bundle::Lister.list(
            Homebrew::Bundle::Brewfile.read(global: context.global, file: context.file).entries,
            formulae:        args.formulae? || args.all? || context.no_type_args,
            casks:           args.casks? || args.all?,
            taps:            args.taps? || args.all?,
            extension_types: context.extensions.to_h do |extension|
              [extension.type, context.extension_selected?(args, extension) || args.all?]
            end,
          )
        end
      end
    end
  end
end
