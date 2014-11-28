require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::RepoSvn do
    it 'registers itself' do
      Command.parse(%w(repo-svn)).should.be.instance_of Command::RepoSvn
    end
  end
end