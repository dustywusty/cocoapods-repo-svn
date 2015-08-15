module Pod
  class Command
    class RepoSvn
      class Remove < RepoSvn
        self.summary = 'Remove a spec repo'

        self.description = <<-DESC
          Deletes the checked out copy named `NAME` from the local spec-repos directory at `~/.cocoapods/repos/.`
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true)
        ]

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          help! 'Deleting a repo needs a `NAME`.' unless @name
          help! "repo #{@name} does not exist" unless File.directory?(dir)
          help! "You do not have permission to delete the #{@name} repository." \
                "Perhaps try prefixing this command with sudo." unless File.writable?(dir)
        end

        def run
          UI.section("Removing spec repo `#{@name}`") do
            FileUtils.rm_rf(dir)
          end
        end
      end
    end
  end
end
