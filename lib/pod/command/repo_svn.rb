require 'fileutils'

module Pod
  class Command
    class RepoSvn < Command
      self.abstract_command = true

      self.summary = 'Manage spec-repositories using subversion'

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
            SourcesManager.check_version_information(dir) #todo: TEST ME
          end
        end
      end

      #-----------------------------------------------------------------------#

      class Update < RepoSvn
        self.summary = 'Update a svn spec-repo.'

        self.description = <<-DESC
          Updates the checked out spec-repo `NAME`.
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
          unless @name
            help! "Updating a spec-repo needs a `NAME`."
          end
        end

        def run
          update(@name, true) #todo: dusty
        end

        #@!group Update helpers
        #-----------------------------------------------------------------------#

        private

        # Slightly modified SourcesManager->update to deal with subversion updates.
        #
        # Original contributors:
        #
        # Fabio Pelosin   http://github.com/irrationalfab
        # Boris Bügling    http://githun.com/neonichu
        #

        # Updates the local copy of the spec-repo with the given name
        #
        # @param  [String] source_name name
        #
        # @return [void]
        #
        def update(source_name = nil, show_output = false)
          if source_name
            sources = [svn_source_named(source_name)]
          else
            sources =  svn_sources
          end

          sources.each do |source|
            UI.section "Updating spec repo `#{source.name}`" do
              Dir.chdir(source.repo) do
                begin
                  #output = svn('up --non-interactive --trust-server-cert')
                  output = `svn up --non-interactive --trust-server-cert`
                  UI.puts output if show_output && !config.verbose?
                rescue Informative => e
                  UI.warn 'CocoaPods was not able to update the ' \
                  "`#{source.name}` repo. If this is an unexpected issue " \
                  'and persists you can inspect it running ' \
                  '`pod repo-svn update --verbose`'
                end
              end
              SourcesManager.check_version_information(source.repo)
            end
          end
        end

        # @return [Source] The svn source with the given name. If no svn source
        #         with given name is found it raises.
        #
        # @param  [String] name
        #         The name of the source.
        #
        def svn_source_named(name)
          specified_source = SourcesManager.aggregate.sources.find { |s| s.name == name }
          unless specified_source
            raise Informative, "Unable to find the `#{name}` repo."
          end
          unless svn_repo?(specified_source.repo)
            raise Informative, "The `#{name}` repo is not a svn repo."
          end
          specified_source
        end

        # @return [Source] The list of the svn sources.
        #
        def svn_sources
          SourcesManager.all.select do |source|
            svn_repo?(source.repo)
          end
        end

        # Returns whether a source is a SVN repo.
        #
        # @param  [Pathname] dir
        #         The directory where the source is stored.
        #
        # @return [Bool] Whether the given source is a SVN repo.
        #
        def svn_repo?(dir)
          Dir.chdir(dir) { `svn info > /dev/null` }
          $?.success?
        end
      end

      #-----------------------------------------------------------------------#

      # ~Verbatim Repo->Lint
      #
      # Original contributors:
      #
      # Fabio Pelosin   http://github.com/irrationalfab
      # Eloy Durán      http://githun.com/alloy

      # Repo validation can probably be pulled out and stuck into core, pretty generic

      #todo: lint is blowing up, fix it - dusty

      class Lint < RepoSvn
        self.summary = 'Validates all specs in a repo.'

        self.description = <<-DESC
          Lints the spec-repo `NAME`. If a directory is provided it is assumed
          to be the root of a repo. Finally, if `NAME` is not provided this
          will lint all the spec-repos known to CocoaPods.
        DESC

        self.arguments = [
            CLAide::Argument.new(%w(NAME DIRECTORY), true)
        ]

        def self.options
          [["--only-errors", "Lint presents only the errors"]].concat(super)
        end

        def initialize(argv)
          @name = argv.shift_argument
          @only_errors = argv.flag?('only-errors')
          super
        end

        # @todo Part of this logic needs to be ported to cocoapods-core so web
        #       services can validate the repo.
        #
        # @todo add UI.print and enable print statements again.
        #
        def run
          if @name
            dirs = File.exists?(@name) ? [ Pathname.new(@name) ] : [ dir ]
          else
            dirs = config.repos_dir.children.select {|c| c.directory?}
          end
          dirs.each do |dir|
            SourcesManager.check_version_information(dir) #todo: test me
            UI.puts "\nLinting spec repo `#{dir.realpath.basename}`\n".yellow

            validator = Source::HealthReporter.new(dir)
            validator.pre_check do |name, version|
              UI.print '.'
            end
            report = validator.analyze
            UI.puts
            UI.puts

            report.pods_by_warning.each do |message, versions_by_name|
              UI.puts "-> #{message}".yellow
              versions_by_name.each { |name, versions| UI.puts "  - #{name} (#{versions * ', '})" }
              UI.puts
            end

            report.pods_by_error.each do |message, versions_by_name|
              UI.puts "-> #{message}".red
              versions_by_name.each { |name, versions| UI.puts "  - #{name} (#{versions * ', '})" }
              UI.puts
            end

            UI.puts "Analyzed #{report.analyzed_paths.count} podspecs files.\n\n"
            if report.pods_by_error.count.zero?
              UI.puts "All the specs passed validation.".green << "\n\n"
            else
              raise Informative, "#{report.pods_by_error.count} podspecs failed validation."
            end
          end
        end
      end

      #-----------------------------------------------------------------------#

      # ~Verbatim Repo->Remove
      #
      # Original contributors:
      #
      # Joshua Kalpin   https://github.com/Kapin
      # Kyle Fuller     https://github.com/kylef

      # Repo removal should probably be pulled out, also pretty generic

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

      #-----------------------------------------------------------------------#
      #
      # Pushes a podspec to the specified repo
      #
      # Most of this was taken directly from the CocoaPods `push` command
      
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

      extend Executable
      executable :svn

      def dir
        config.repos_dir + @name
      end
    end
  end
end