module SpecHelper
  def self.tmp_repos_path
    TemporaryRepos.tmp_repos_path
  end

  module TemporaryRepos
    extend Pod::Executable
    executable :svn

    # ..

    def make_svn_repo
      return unless !File.directory?(tmp_svn_path)
        `svnadmin create #{tmp_svn_path}`
        `svn import #{tmp_repos_path} file://#{tmp_svn_path} -m "import"`
    end

    # ..

    def set_up_test_repo()
        tmp_repos_path.mkpath
        origin = ROOT + 'spec/fixtures/spec-repos/test-repo/'
        destination = tmp_repos_path
        FileUtils.cp_r(origin, destination)
        make_svn_repo
    end

    # ..

    def tmp_repos_path
      SpecHelper.temporary_directory + 'cocoapods/repos/master'
    end

    # ..

    def tmp_svn_path
      SpecHelper.temporary_directory + 'svn'
    end

    module_function :tmp_repos_path

    def self.extended(base)
      base.before do
        tmp_repos_path.mkpath
      end
    end

  end
end
