require 'fileutils'

module Pod
  class Command
    class RepoSvn < Command
      require 'pod/command/repo_svn/add'
      require 'pod/command/repo_svn/lint'
      require 'pod/command/repo_svn/push'
      require 'pod/command/repo_svn/remove'
      require 'pod/command/repo_svn/update'

      self.abstract_command = true
      self.summary = 'Manage spec-repositories using subversion'

      #-----------------------------------------------------------------------#

      extend Executable
      executable :svn

      def dir
        config.repos_dir + @name
      end
    end
  end
end