module Pod
  class Command
    class RepoSvn
      class Push < RepoSvn
        self.summary = 'Push a podspec'

        self.description = <<-DESC
                Validates `NAME.podspec` or `*.podspec` in the current working dir, creates a
                directory and version folder for the pod in the local copy of `REPO`
                (~/.cocoapods/repos/[REPO]), copies the podspec file into the version directory,
                and finally it commits the changes to `REPO`
        DESC

        self.arguments = [
            CLAide::Argument.new('REPO', true),
            CLAide::Argument.new('NAME.podspec', false)
        ]

        def self.options
          [['--local-only', 'Does not perform the step of committing changes to REPO']].concat(super)
        end

        def initialize(argv)
          @local_only = argv.flag?('local-only')
          @repo = argv.shift_argument
          @podspec = argv.shift_argument
          super
        end

        def validate!
          super
          help! 'A spec-repo name is required.' unless @repo
        end

        def run
          update_repo
          add_specs_to_repo
        end

        # Updates the git repo against the remote.
        #
        # @return [void]
        #
        def update_repo
          UI.puts "Updating the `#{@repo}' repo\n".yellow
          Dir.chdir(repo_dir) { UI.puts `svn update .` }
        end

        def add_specs_to_repo
          UI.puts "\nAdding the #{'spec'.pluralize(podspec_files.count)} to the `#{@repo}' repo\n".yellow
          podspec_files.each do |spec_file|
            spec = Pod::Specification.from_file(spec_file)
            output_path = File.join(repo_dir, spec.name, spec.version.to_s)
            if Pathname.new(output_path).exist?
              message = "[Fix] #{spec}"
            elsif Pathname.new(File.join(repo_dir, spec.name)).exist?
              message = "[Update] #{spec}"
            else
              message = "[Add] #{spec}"
            end

            FileUtils.mkdir_p(output_path)
            FileUtils.cp(spec_file, output_path)
            if !@local_only
              Dir.chdir(repo_dir) do
                # only commit if modified
                UI.puts "Committing changes"
                UI.puts `svn add #{spec.name} 2> /dev/null`
                UI.puts `svn commit -m "#{message}"`
              end
            end
          end
        end

        private

        # @return [Array<Pathname>] The path of the specifications to push.
        #
        def podspec_files
          if @podspec
            path = Pathname(@podspec)
            raise Informative, "Couldn't find #{@podspec}" unless path.exist?
            [path]
          else
            files = Pathname.glob('*.podspec{,.json}')
            raise Informative, "Couldn't find any podspec files in current directory" if files.empty?
            files
          end
        end

        # @return [Pathname] The directory of the repository.
        #
        def repo_dir
          specs_dir = Pathname.new(File.join(config.repos_dir, @repo, 'Specs'))
          dir = config.repos_dir + @repo
          if specs_dir.exist?
            dir = specs_dir
          elsif dir.exist?
            dir
          else
            raise Informative, "`#{@repo}` repo not found either in #{specs_dir} or #{dir}"
          end
          dir
        end
      end
    end
  end
end