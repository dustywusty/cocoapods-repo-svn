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
            CLAide::Argument.new('URL', true),
            CLAide::Argument.new('NAME', true)
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
              !svn(command)
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
            CLAide::Argument.new('NAME', true),
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
            specified_source = SourcesManager.aggregate.all.find { |s| s.name == source_name }
            raise Informative, "Unable to find the `#{source_name}` spec-repo."    unless specified_source
            raise Informative, "The `#{source_name}` repo is not a svn spec-repo." unless svn_repo?(specified_source.data_provider.repo)
            sources = [specified_source]
          end

          sources.each do |source|
            UI.section "Updating spec-repo `#{source.name}`" do
              Dir.chdir(source.data_provider.repo) do
                output = svn!('up --non-interactive --trust-server-cert')
                UI.puts output if show_output && !config.verbose?
              end
              SourcesManager.check_version_information(source.data_provider.repo) #todo: test me
            end
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
          Dir.chdir(dir) { svn('info  >/dev/null 2>&1') }
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
            CLAide::Argument.new(%w(NAME DIRECTORY), true),
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
            CLAide::Argument.new('NAME', true),
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

      extend Executable
      executable :svn

      def dir
        config.repos_dir + @name
      end
    end
  end
end