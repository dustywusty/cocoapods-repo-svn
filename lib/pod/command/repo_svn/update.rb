module Pod
  class Command
    class RepoSvn
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
              # SourcesManager.check_version_information(source.repo)
              Config.instance.sources_manager.sources([source.repo.basename.to_s]).each(&:verify_compatibility!) #todo: TEST ME
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
          # SourcesManager.all.select do |source|
          #   svn_repo?(source.repo)
          # end
          Config.instance.sources_manager.all.select do |source|
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
    end
  end
end
