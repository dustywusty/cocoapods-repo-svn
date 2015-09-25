require 'pod/command/repo_svn'
require 'svn_source'

# This pre_install hook requires cocoapods v. 0.38.0.beta.2 or higher
Pod::HooksManager.register('cocoapods-repo-svn', :source_provider) do |context, options|
    Pod::UI.message 'cocoapods-repo-svn received source_provider hook'
    return unless sources = options['sources']
    sources.each do |url|
        source = create_source_with_url(url)
        update_or_add_source(source)
        context.add_source(source)
    end
end

# @param [Source] source The source to add or update
#
# @return [Void]
#
def update_or_add_source(source)
    name = source.name
    url = source.url
    dir = source.repo

    if dir.exist?
        argv = CLAide::ARGV.new([name])
        cmd = Pod::Command::RepoSvn::Update.new(argv)
    else
        argv = CLAide::ARGV.new([name, url])
        cmd = Pod::Command::RepoSvn::Add.new(argv)
    end

    cmd.run()
end

# @param [String] url The URL of the SVN repository
#
# @return [String] a name for the repository
#
# For now, this uses the last component of the URL as the name
# So https://my.server.com/somedir/Specs will return Specs
def name_for_url(url)
    return nil unless url
    delim = '/'
    components = url.split(delim)
    components.last
end


def create_source_with_url(url)
    name = name_for_url(url)
    repos_dir = Pod::Config.instance.repos_dir
    repo = repos_dir + name
    Pod::SvnSource.new(repo,url)
end
