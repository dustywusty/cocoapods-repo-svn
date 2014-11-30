require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::RepoSvn::Add do
    it 'registers itself' do
      Command.parse(%w( repo-svn add )).should.be.instance_of Command::RepoSvn::Add
    end

    it 'fails without a repository url or name' do
      command = Command.parse(%w( repo-svn add ))
      lambda { command.validate! }.should.raise CLAide::InformativeError
    end
  end
end