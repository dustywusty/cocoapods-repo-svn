require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::RepoSvn do
    describe 'repo-svn' do
      it 'registers itself as a command' do
        Command.parse(%w(repo-svn)).should.be.instance_of Command::RepoSvn
      end
    end
  end
end