require File.expand_path('../../../spec_helper', __FILE__)
include CLAide::InformativeError

module Pod
  describe Command::RepoSvn::Update do
    it 'returns the proper command class' do
      Command.parse(%w( repo-svn update )).should.be.instance_of Command::RepoSvn::Update
    end

    it 'fails without a repository name' do
      command = Command.parse(%w( repo-svn update ))
      lambda { command.validate! }.should.raise CLAide::InformativeError
    end

    # it 'updates a repository' do
    #   #
    # end
  end
end
