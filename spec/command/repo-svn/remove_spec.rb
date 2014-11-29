require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::RepoSvn::Remove do
      it 'registers itself' do
        Command.parse(%w( repo-svn remove )).should.be.instance_of Command::RepoSvn::Remove
      end

      it 'fails without a repository name' do
        command = Command.parse(%w( repo-svn remove ))
        lambda { command.validate! }.should.raise CLAide::InformativeError
      end
  end
end