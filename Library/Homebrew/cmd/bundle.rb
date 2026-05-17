# typed: strict
# frozen_string_literal: true

require "abstract_command"
require "bundle/dsl"
require "bundle/extensions"

module Homebrew
  module Cmd
    class Bundle < AbstractCommand
      require "bundle/subcommand"

      BUNDLE_EXTENSIONS = T.let(Homebrew::Bundle.extensions.dup.freeze, T::Array[T.class_of(Homebrew::Bundle::Extension)])
      BUNDLE_SOURCES_DESCRIPTION = T.let(
        [
          "Homebrew",
          "Homebrew Cask",
          *BUNDLE_EXTENSIONS.map(&:banner_name),
        ].to_sentence.freeze,
        String,
      )

      cmd_args do
        usage_banner <<~EOS
          `bundle` [<subcommand>]

          Bundler for non-Ruby dependencies from #{BUNDLE_SOURCES_DESCRIPTION}.

          Note: Flatpak support is only available on Linux.
        EOS
        flag "--file=",
             description: "Read from or write to the `Brewfile` from this location. " \
                          "Use `--file=-` to pipe to stdin/stdout."
        switch "-g", "--global",
               description: "Read from or write to the `Brewfile` from `$HOMEBREW_BUNDLE_FILE_GLOBAL` " \
                            "(if set), `${XDG_CONFIG_HOME}/homebrew/Brewfile` " \
                            "(if `$XDG_CONFIG_HOME` is set), `~/.homebrew/Brewfile` or `~/.Brewfile` otherwise."

        Homebrew::AbstractSubcommand.define_all(self, command: Homebrew::Cmd::Bundle)

        BUNDLE_EXTENSIONS.select(&:dump_disable_supported?).each do |extension|
          conflicts "--#{extension.flag}", "--no-#{extension.flag}"
        end
        conflicts "--file", "--global"
      end

      sig { override.void }
      def run
        # Keep this inside `run` to keep --help fast.
        require "bundle"

        Homebrew::Cmd::Bundle.dispatch(args, extensions: BUNDLE_EXTENSIONS)
      end
    end
  end
end
