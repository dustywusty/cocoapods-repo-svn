module Pod
  # Subclass of Pod::Source to provide support for SVN Specs repositories
  #
  class SvnSource < Source
    # @return [String] The remote URL of the repository
    #
    attr_accessor :url

    # @param [String] repo The name of the repository (aka. directory name)
    #
    # @param [String] url see {#url}
    #
    def initialize(repo, url)
      super(repo)
      @url = url
    end
  end
end