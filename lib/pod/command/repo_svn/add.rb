module Pod
  class Command
    class RepoSvn
      class Add < RepoSvn
        self.summary = 'Add a spec-repo using svn.'

        self.description = <<-DESC
          Check out `URL` in the local spec-repos directory at `~/.cocoapods/repos/`. The
          remote can later be referred to by `NAME`.
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true),
            CLAide::Argument.new('URL', true)
        ]

        def initialize(argv)
          @name, @url = argv.shift_argument, argv.shift_argument
          super
        end

        def validate!
          super
          unless @name && @url
            help! "Adding a spec-repo needs a `NAME` and a `URL`."
          end
        end

        def run
          UI.section("Checking out spec-repo `#{@name}` from `#{@url}` using svn") do
            config.repos_dir.mkpath
            Dir.chdir(config.repos_dir) do
              command = "checkout --non-interactive --trust-server-cert '#{@url}' #{@name}"
              #!svn(command)
              `svn #{command}`
            end
            # SourcesManager.check_version_information(dir) #todo: TEST ME
            Config.instance.sources_manager.sources([dir.basename.to_s]).each(&:verify_compatibility!) #todo: TEST ME
          end
        end
      end
    end
  end
end
